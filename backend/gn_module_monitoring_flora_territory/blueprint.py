import datetime
import logging


from flask import Blueprint, request, session, send_from_directory
from geoalchemy2.shape import to_shape
from geojson import FeatureCollection
from sqlalchemy import and_, distinct, select
from sqlalchemy.orm import joinedload, load_only
from sqlalchemy.sql.expression import func


from apptax.taxonomie.models import Taxref
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_monitoring.models import (
    corVisitObserver,
    TBaseVisits,
    corSiteModule,
    corSiteArea,
)
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import get_or_fetch_user_cruved
from geonature.core.ref_geo.models import LAreas, BibAreasTypes
from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilsgeometry import FionaShapeService
from pypnnomenclature.models import TNomenclatures
from pypnusershub.db.models import Organisme, User
from utils_flask_sqla.response import json_resp, to_json_resp, to_csv_resp


from .models import (
    TInfoSite,
    TVisiteSFT,
    CorVisitGrid,
    ExportVisits,
)
from .repositories import check_user_cruved_visit, check_year_visit
from .utils import prepare_output, prepare_input, fprint


blueprint = Blueprint("pr_suivi_flore_territoire", __name__)
log = logging.getLogger(__name__)


@blueprint.route("/sites", methods=["GET"])
@json_resp
def get_sites():
    """
    Retourne la liste des ZP
    """
    parameters = request.args
    id_type_commune = blueprint.config["id_type_commune"]

    # Query to get Sites id
    query = DB.session.query(distinct(TInfoSite.id_infos_site)).select_from(
        TInfoSite.__table__.outerjoin(
            TBaseVisits, TBaseVisits.id_base_site == TInfoSite.id_base_site
        )
        .outerjoin(
            corVisitObserver,
            corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit,
        )
        .outerjoin(User, User.id_role == corVisitObserver.c.id_role)
        .outerjoin(Organisme, Organisme.id_organisme == User.id_organisme)
        .outerjoin(corSiteArea, corSiteArea.c.id_base_site == TInfoSite.id_base_site)
        .outerjoin(
            LAreas,
            and_(
                LAreas.id_area == corSiteArea.c.id_area,
                LAreas.id_type == id_type_commune,
            ),
        )
    )

    if "id_base_site" in parameters:
        query = query.filter(TInfoSite.id_base_site == parameters["id_base_site"])

    if "cd_nom" in parameters:
        query = query.filter(TInfoSite.cd_nom == parameters["cd_nom"])

    if "organisme" in parameters:
        query = query.filter(Organisme.nom_organisme == parameters["organisme"])

    if "commune" in parameters:
        query = query.filter(LAreas.area_name == parameters["commune"])

    if "year" in parameters:
        query = query.filter(
            func.date_part("year", TBaseVisits.visit_date_min) == parameters["year"]
        )
    idSiteList = query.all()

    # Query to get Sites data with previous id
    query = (
        DB.session.query(
            TInfoSite,
            func.max(TBaseVisits.visit_date_min),
            Taxref.nom_complet,
            func.count(distinct(TBaseVisits.id_base_visit)),
            func.string_agg(distinct(Organisme.nom_organisme), ", "),
            func.string_agg(distinct(LAreas.area_name), ", "),
        )
        .select_from(
            TInfoSite.__table__.outerjoin(
                TBaseVisits, TBaseVisits.id_base_site == TInfoSite.id_base_site
            )
            .outerjoin(
                corVisitObserver,
                corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit,
            )
            .outerjoin(User, User.id_role == corVisitObserver.c.id_role)
            .outerjoin(Organisme, Organisme.id_organisme == User.id_organisme)
            .outerjoin(Taxref, TInfoSite.cd_nom == Taxref.cd_nom)
            .outerjoin(corSiteArea, corSiteArea.c.id_base_site == TInfoSite.id_base_site)
            .outerjoin(
                LAreas,
                and_(
                    LAreas.id_area == corSiteArea.c.id_area,
                    LAreas.id_type == id_type_commune,
                ),
            )
        )
        .filter(TInfoSite.id_infos_site.in_(idSiteList))
        .group_by(TInfoSite, Taxref.nom_complet)
    )
    data = query.all()

    features = []
    for d in data:
        feature = d[0].get_geofeature()
        # Year
        feature["properties"]["date_max"] = str(d[1])
        if d[1] == None:
            feature["properties"]["date_max"] = "Aucune visite"

        # Taxon
        feature["properties"]["nom_taxon"] = str(d[2])

        # Visit
        feature["properties"]["nb_visit"] = str(d[3])

        # Organisme
        feature["properties"]["organisme"] = str(d[4])
        if d[4] == None:
            feature["properties"]["organisme"] = "Aucun"

        # Commune
        feature["properties"]["nom_commune"] = str(d[5])

        features.append(feature)
    return FeatureCollection(features)


@blueprint.route("/sites/<int:id_info_site>", methods=["GET"])
@json_resp
def get_one_site(id_info_site):
    """
    Retourne les infos d'un site à partir de l'id_info_site
    """
    (base_site_infos, municipalities) = (
        DB.session.query(
            TInfoSite,
            func.string_agg(
                distinct(func.concat(LAreas.area_name, " (", LAreas.area_code, ")")), ", "
            ).filter(LAreas.area_name != None),
        )
        .outerjoin(corSiteArea, corSiteArea.c.id_base_site == TInfoSite.id_base_site)
        .outerjoin(LAreas, LAreas.id_area == corSiteArea.c.id_area)
        .join(
            BibAreasTypes,
            and_(BibAreasTypes.id_type == LAreas.id_type, BibAreasTypes.type_code == "COM"),
        )
        .filter(TInfoSite.id_base_site == id_info_site)
        .group_by(TInfoSite.id_infos_site)
        .first()
    )

    infos_site = base_site_infos.as_dict(fields=["base_site", "sciname"])
    fprint(infos_site)
    output = infos_site["base_site"]
    output["sciname"] = {
        "code": infos_site["cd_nom"],
        "label": infos_site["sciname"]["nom_complet_html"],
    }
    output["municipalities"] = municipalities
    return prepare_output(output, remove_in_key="base_site")


@blueprint.route("/visits", methods=["GET"])
@json_resp
def get_visits():
    """
    Retourne toutes les visites du module
    """
    parameters = request.args
    q = DB.session.query(TVisiteSFT)
    if "id_base_site" in parameters:
        q = q.filter(TVisiteSFT.id_base_site == parameters["id_base_site"])
    data = q.all()
    return [d.as_dict(True) for d in data]


@blueprint.route("/visits/<id_visit>", methods=["GET"])
@json_resp
def get_one_visit(id_visit):
    """
    Retourne une visite
    """
    data = DB.session.query(TVisiteSFT).get(id_visit)
    return data.as_dict(recursif=True)


@blueprint.route("/visits", methods=["POST"])
@permissions.check_cruved_scope("R", True)
@json_resp
def add_visit(info_role):
    """
    Poste une nouvelle visite ou édite une ancienne
    """
    data = dict(request.get_json())

    # if its not an update we check if there is not aleady a visit this year
    if not data["id_base_visit"]:
        check_year_visit(data["id_base_site"], data["visit_date_min"][0:4])

    # Set generic infos got from config
    data["id_dataset"] = blueprint.config["id_dataset"]
    data["id_module"] = (
        DB.session.query(TModules.id_module)
        .filter(TModules.module_code == blueprint.config["MODULE_CODE"])
        .scalar()
    )

    try:
        tab_perturbation = data.pop("cor_visit_perturbation")
    except:
        pass

    if "cor_visit_grid" in data:
        tab_visit_grid = data.pop("cor_visit_grid")
    else:
        tab_visit_grid = None

    tab_observer = data.pop("cor_visit_observer")

    visit = TVisiteSFT(**data)
    visit.as_dict(True)
    # pour que visit prenne en compte des relations
    # sinon elle prend pas en compte le fait qu'on efface toutes les perturbations quand on édite par ex.
    try:
        perturs = (
            DB.session.query(TNomenclatures)
            .filter(TNomenclatures.id_nomenclature.in_(tab_perturbation))
            .all()
        )
        for per in perturs:
            visit.cor_visit_perturbation.append(per)
    except:
        pass

    if tab_visit_grid is not None:
        for v in tab_visit_grid:
            visit_grid = CorVisitGrid(**v)
            visit.cor_visit_grid.append(visit_grid)

    observers = DB.session.query(User).filter(User.id_role.in_(tab_observer)).all()
    for o in observers:
        visit.observers.append(o)

    if visit.id_base_visit:
        user_cruved = get_or_fetch_user_cruved(
            session=session, id_role=info_role.id_role, module_code="SFT"
        )
        update_cruved = user_cruved["U"]
        check_user_cruved_visit(info_role, visit, update_cruved)
        DB.session.merge(visit)
    else:
        DB.session.add(visit)

    DB.session.commit()

    return visit.as_dict(recursif=True)


@blueprint.route("/export_visit", methods=["GET"])
def export_visits():
    """
    Télécharge les données d'une visite (ou des visites )
    """

    parameters = request.args
    # q = q.filter(TInfoSite.id_base_site == parameters['id_base_site'])

    export_format = parameters["export_format"] if "export_format" in request.args else "shapefile"

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    q = DB.session.query(ExportVisits)

    if "id_base_visit" in parameters:
        q = DB.session.query(ExportVisits).filter(
            ExportVisits.id_base_visit == parameters["id_base_visit"]
        )
    elif "id_base_site" in parameters:
        q = DB.session.query(ExportVisits).filter(
            ExportVisits.id_base_site == parameters["id_base_site"]
        )
    elif "organisme" in parameters:
        q = DB.session.query(ExportVisits).filter(ExportVisits.organisme == parameters["organisme"])
    elif "commune" in parameters:
        q = DB.session.query(ExportVisits).filter(ExportVisits.area_name == parameters["commune"])
    elif "year" in parameters:
        q = DB.session.query(ExportVisits).filter(
            func.date_part("year", ExportVisits.visit_date) == parameters["year"]
        )
    elif "cd_nom" in parameters:
        q = DB.session.query(ExportVisits).filter(ExportVisits.cd_nom == parameters["cd_nom"])

    data = q.all()
    features = []

    if export_format == "geojson":
        for d in data:
            feature = d.as_geofeature("geom", "id_area", False)
            features.append(feature)
        result = FeatureCollection(features)

        return to_json_resp(result, as_file=True, filename=file_name, indent=4)

    elif export_format == "csv":
        tab_visit = []

        for d in data:
            visit = d.as_dict()
            geom_wkt = to_shape(d.geom)
            visit["geom"] = geom_wkt

            tab_visit.append(visit)

        return to_csv_resp(file_name, tab_visit, tab_visit[0].keys(), ";")

    else:

        dir_path = str(ROOT_DIR / "backend/static/shapefiles")

        FionaShapeService.create_shapes_struct(
            db_cols=ExportVisits.__mapper__.c,
            srid=2154,
            dir_path=dir_path,
            file_name=file_name,
        )

        for row in data:
            FionaShapeService.create_feature(row.as_dict(), row.geom)

        FionaShapeService.save_and_zip_shapefiles()

        return send_from_directory(dir_path, file_name + ".zip", as_attachment=True)


@blueprint.route("/commune/<module_code>", methods=["GET"])
@json_resp
def get_commune(module_code):
    """
    Retourne toutes les communes présents dans le module
    """
    params = request.args

    query = (
        select([LAreas.area_name.distinct()])
        .select_from(
            LAreas.__table__.outerjoin(corSiteArea, LAreas.id_area == corSiteArea.c.id_area)
            .outerjoin(
                corSiteModule,
                corSiteModule.c.id_base_site == corSiteArea.c.id_base_site,
            )
            .outerjoin(
                TModules,
                TModules.id_module == corSiteModule.c.id_module,
            )
        )
        .where(TModules.module_code == module_code)
    )

    if "id_area_type" in params:
        query = query.where(LAreas.id_type == params["id_area_type"])

    data = DB.engine.execute(query)

    municipalities = []
    for d in data:
        municipality = {
            "nom_commune": str(d[0]),
        }
        municipalities.append(municipality)
    return municipalities


@blueprint.route("/organisms", methods=["GET"])
@json_resp
def get_organisme():
    """
    Retourne la liste de tous les organismes présents
    """
    query = select(
        [Organisme.nom_organisme.distinct(), User.nom_role, User.prenom_role]
    ).select_from(
        User.__table__.outerjoin(Organisme, User.id_organisme == Organisme.id_organisme)
        .join(corVisitObserver, User.id_role == corVisitObserver.c.id_role)
        .outerjoin(TVisiteSFT, corVisitObserver.c.id_base_visit == TVisiteSFT.id_base_visit)
    )
    data = DB.engine.execute(query)

    organisms = []
    for d in data:
        organism = {
            "nom_organisme": str(d[0]),
            "observer": f"{d[1]} {d[2]}",
        }
        organisms.append(organism)
    return organisms
