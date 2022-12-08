import datetime
import logging


from flask import Blueprint, request, session, send_from_directory
from geoalchemy2.shape import to_shape
from geojson import FeatureCollection
from sqlalchemy import and_, distinct, desc
from sqlalchemy.orm import joinedload
from sqlalchemy.sql.expression import func


from apptax.taxonomie.models import Taxref
from geonature.core.gn_commons.models import TModules
from geonature.core.gn_monitoring.models import (
    corSiteModule,
    corSiteArea,
    corVisitObserver,
    TBaseVisits,
)
from geonature.core.gn_permissions import decorators as permissions
from geonature.core.gn_permissions.tools import cruved_scope_for_user_in_module
from geonature.core.ref_geo.models import LAreas, BibAreasTypes
from geonature.utils.env import db, ROOT_DIR

from pypnusershub.db.models import Organisme, User
from utils_flask_sqla.response import json_resp, to_json_resp, to_csv_resp
from utils_flask_sqla_geo.utilsgeometry import FionaShapeService


from .models import (
    VisitGrid,
    VisitPerturbation,
    VisitsExport,
    SiteInfos,
    Visit,
)
from .repositories import check_user_cruved_visit, check_year_visit
from .utils import prepare_output, prepare_input, fprint


blueprint = Blueprint("pr_monitoring_flora_territory", __name__)
log = logging.getLogger(__name__)


@blueprint.route("/sites", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SFT")
@json_resp
def get_sites():
    """
    Retourne la liste des sites.
    """
    parameters = request.args

    # "From" shared between two queries
    from_clause = (
        SiteInfos.__table__.outerjoin(
            TBaseVisits, TBaseVisits.id_base_site == SiteInfos.id_base_site
        )
        .outerjoin(
            corVisitObserver,
            corVisitObserver.c.id_base_visit == TBaseVisits.id_base_visit,
        )
        .outerjoin(User, User.id_role == corVisitObserver.c.id_role)
        .outerjoin(Organisme, Organisme.id_organisme == User.id_organisme)
        .outerjoin(corSiteArea, corSiteArea.c.id_base_site == SiteInfos.id_base_site)
        .outerjoin(LAreas, LAreas.id_area == corSiteArea.c.id_area)
        .outerjoin(
            BibAreasTypes,
            and_(BibAreasTypes.id_type == LAreas.id_type, BibAreasTypes.type_code == "COM"),
        )
    )

    # Query to get Sites id
    query = db.session.query(distinct(SiteInfos.id_infos_site)).select_from(from_clause)

    if "id_base_site" in parameters:
        query = query.filter(SiteInfos.id_base_site == parameters["id_base_site"])

    if "cd_nom" in parameters:
        query = query.filter(SiteInfos.cd_nom == parameters["cd_nom"])

    if "organism" in parameters and parameters["organism"] != "null":
        query = query.filter(Organisme.id_organisme == parameters["organism"])

    if "municipality" in parameters and parameters["municipality"] != "null":
        query = query.filter(LAreas.id_area == parameters["municipality"])

    if "year" in parameters and parameters["year"] != "null":
        query = query.filter(
            func.date_part("year", TBaseVisits.visit_date_min) == parameters["year"]
        )

    id_site_list = query.all()

    # Query to get Sites data with previous id
    query = (
        db.session.query(
            SiteInfos,
            func.max(TBaseVisits.visit_date_min),
            Taxref.nom_complet,
            func.count(distinct(TBaseVisits.id_base_visit)),
            func.string_agg(distinct(Organisme.nom_organisme), ", "),
            func.string_agg(distinct(LAreas.area_name), ", "),
        )
        .select_from(from_clause.outerjoin(Taxref, SiteInfos.cd_nom == Taxref.cd_nom))
        .filter(SiteInfos.id_infos_site.in_(id_site_list))
        .group_by(SiteInfos, Taxref.nom_complet)
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


@blueprint.route("/sites/<int:id_base_site>", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SFT")
@json_resp
def get_one_site(id_base_site):
    """
    Retourne les infos d'un site à partir de l'id_base_site
    """
    base_site_infos = (
        db.session.query(SiteInfos).filter(SiteInfos.id_base_site == id_base_site).first()
    )
    municipalities = (
        db.session.query(
            func.string_agg(
                distinct(func.concat(LAreas.area_name, " (", LAreas.area_code, ")")), ", "
            ).filter(LAreas.area_name != None),
        )
        .select_from(
            SiteInfos.__table__.outerjoin(
                corSiteArea, corSiteArea.c.id_base_site == SiteInfos.id_base_site
            )
            .outerjoin(LAreas, LAreas.id_area == corSiteArea.c.id_area)
            .join(
                BibAreasTypes,
                and_(BibAreasTypes.id_type == LAreas.id_type, BibAreasTypes.type_code == "COM"),
            )
        )
        .filter(SiteInfos.id_base_site == id_base_site)
        .scalar()
    )

    infos_site = base_site_infos.as_dict(fields=["base_site", "sciname"])
    output = infos_site["base_site"]
    output["sciname"] = {
        "code": infos_site["cd_nom"],
        "label": infos_site["sciname"]["nom_complet_html"],
    }
    output["municipalities"] = municipalities
    return prepare_output(output, remove_in_key="base_site")


@blueprint.route("/visits", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SFT")
@json_resp
def get_visits():
    """
    Retourne toutes les visites du module
    """
    parameters = request.args
    query = db.session.query(Visit)
    if "id_base_site" in parameters:
        query = query.filter(Visit.id_base_site == parameters["id_base_site"])
    data = query.all()
    fields = get_visit_fields()
    return [d.as_dict(fields=fields) for d in data]


@blueprint.route("/visits/<int:id_visit>", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SFT")
@json_resp
def get_one_visit(id_visit):
    """
    Retourne une visite
    """
    return get_visit_details(id_visit)


def get_visit_details(id_visit):
    data = (
        db.session.query(Visit)
        .options(joinedload(Visit.cor_visit_perturbation))
        .filter(Visit.id_base_visit == id_visit)
        .first()
    )
    fields = get_visit_fields()
    return data.as_dict(fields=fields)


def get_visit_fields():
    return [
        "id_base_visit",
        "id_base_site",
        "visit_date_min",
        "comments",
        "cor_visit_grid",
        "cor_visit_perturbation.nomenclature",
        "observers",
    ]


@blueprint.route("/visits", methods=["POST"])
@permissions.check_cruved_scope("C", True, module_code="SFT")
@json_resp
def add_visit(info_role):
    return edit_visit(info_role)


@blueprint.route("/visits/<int:id_visit>", methods=["PATCH"])
@permissions.check_cruved_scope("U", True, module_code="SFT")
@json_resp
def update_visit(id_visit, info_role):
    return edit_visit(info_role, id_visit)


def edit_visit(info_role, id_visit=None):
    """
    Ajoute une nouvelle visite ou édite une ancienne
    """
    data = dict(request.get_json())

    # Check data
    check_year_visit(data["id_base_site"], data["visit_date_min"][0:4], id_base_visit=id_visit)

    # Set generic infos got from config
    data["id_dataset"] = blueprint.config["id_dataset"]
    data["id_module"] = (
        db.session.query(TModules.id_module)
        .filter(TModules.module_code == blueprint.config["MODULE_CODE"])
        .scalar()
    )
    if not id_visit:
        data["id_digitiser"] = info_role.id_role

    # Extract data
    perturbations_ids = []
    if "cor_visit_perturbation" in data:
        perturbations_ids = data.pop("cor_visit_perturbation")
    visit_grids = []
    if "cor_visit_grid" in data:
        visit_grids = data.pop("cor_visit_grid")
    observers_ids = []
    if "cor_visit_observer" in data:
        observers_ids = data.pop("cor_visit_observer")

    # Create visit object
    visit = Visit(**data)

    # Add/Update perturbations
    if id_visit:
        db.session.query(VisitPerturbation).filter_by(id_base_visit=id_visit).delete()
    for perturbation_id in perturbations_ids:
        perturbation = {"id_nomenclature_perturbation": perturbation_id}
        if id_visit:
            perturbation["id_base_visit"] = id_visit
        visit_perturbation = VisitPerturbation(**perturbation)
        visit.cor_visit_perturbation.append(visit_perturbation)

    # Add/Update grids
    if id_visit:
        db.session.query(VisitGrid).filter_by(id_base_visit=id_visit).delete()
    for grid in visit_grids:
        visit_grid = VisitGrid(**grid)
        visit.cor_visit_grid.append(visit_grid)

    # Add/Update observers
    observers = db.session.query(User).filter(User.id_role.in_(observers_ids)).all()
    for observer in observers:
        visit.observers.append(observer)

    # Add/Update database
    if id_visit:
        (user_cruved, is_herited) = cruved_scope_for_user_in_module(
            id_role=info_role.id_role, module_code=blueprint.config["MODULE_CODE"]
        )
        update_cruved = user_cruved["U"]
        check_user_cruved_visit(info_role, visit, update_cruved)
        visit = db.session.merge(visit)
    else:
        db.session.add(visit)

    db.session.commit()
    if not id_visit:
        db.session.refresh(visit)

    return get_visit_details(visit.id_base_visit)


@blueprint.route("/visits/export", methods=["GET"])
@permissions.check_cruved_scope("E", module_code="SFT")
def export_visits():
    """
    Télécharge les données d'une visite (ou des visites )
    """
    parameters = request.args
    export_format = parameters["export_format"] if "export_format" in request.args else "shapefile"

    query = db.session.query(VisitsExport)
    if "id_base_visit" in parameters:
        query = query.filter(VisitsExport.id_base_visit == parameters["id_base_visit"])

    if "id_base_site" in parameters:
        query = query.filter(VisitsExport.id_base_site == parameters["id_base_site"])

    if "organisme" in parameters:
        query = query.filter(VisitsExport.organisme == parameters["organisme"])

    if "commune" in parameters:
        query = query.filter(VisitsExport.area_name == parameters["commune"])

    if "year" in parameters:
        query = query.filter(func.date_part("year", VisitsExport.visit_date_min) == parameters["year"])

    if "cd_nom" in parameters:
        query = query.filter(VisitsExport.cd_nom == parameters["cd_nom"])

    results = query.all()

    file_name = datetime.datetime.now().strftime("%Y_%m_%d_%Hh%Mm%S")
    if export_format == "geojson":
        features = []
        for data in results:
            feature = data.as_geofeature("geom", "id_area", False)
            features.append(feature)
        geojson = FeatureCollection(features)
        return to_json_resp(
            geojson, as_file=True, filename=file_name, indent=4, extension="geojson"
        )
    elif export_format == "csv":
        visits = []
        for data in results:
            visit = data.as_dict()
            geom_wkt = to_shape(data.geom)
            visit["geom"] = geom_wkt

            visits.append(visit)
        headers = visits[0].keys()
        return to_csv_resp(file_name, visits, headers, ";")
    else:
        dir_path = str(ROOT_DIR / "backend/static/shapefiles")
        FionaShapeService.create_fiona_struct(
            db_cols=VisitsExport.__mapper__.c,
            srid=2154,
            dir_path=dir_path,
            file_name=file_name,
        )
        for data in results:
            FionaShapeService.create_feature(data.as_dict(), data.geom)
        FionaShapeService.save_files()
        return send_from_directory(dir_path, file_name + ".zip", as_attachment=True)


@blueprint.route("/visits/years", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SFT")
@json_resp
def get_visits_years():
    """
    Retourne toutes les années de visites du module.
    """
    query = (
        db.session.query(func.to_char(Visit.visit_date_min, "YYYY"))
        .join(SiteInfos, SiteInfos.id_base_site == Visit.id_base_site)
        .order_by(desc(func.to_char(Visit.visit_date_min, "YYYY")))
        .group_by(func.to_char(Visit.visit_date_min, "YYYY"))
    )
    results = query.all()

    years = []
    for row in results:
        years.append(row[0])
    return years


@blueprint.route("/municipalities", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SFT")
@json_resp
def get_municipalities():
    """
    Retourne toutes les communes liées au module.
    """
    query = (
        db.session.query(LAreas)
        .join(BibAreasTypes, BibAreasTypes.id_type == LAreas.id_type)
        .join(corSiteArea, LAreas.id_area == corSiteArea.c.id_area)
        .join(corSiteModule, corSiteModule.c.id_base_site == corSiteArea.c.id_base_site)
        .join(TModules, TModules.id_module == corSiteModule.c.id_module)
        .filter(TModules.module_code == blueprint.config["MODULE_CODE"])
        .filter(BibAreasTypes.type_code == "COM")
    )
    results = query.all()

    output = []
    for area in results:
        output.append(area.as_dict())

    return prepare_output(output, remove_in_key="area")


@blueprint.route("/organisms", methods=["GET"])
@permissions.check_cruved_scope("R", module_code="SFT")
@json_resp
def get_organisms():
    """
    Retourne la liste de tous les organismes liés au module.
    """
    query = (
        db.session.query(Organisme)
        .join(User, User.id_organisme == Organisme.id_organisme)
        .join(corVisitObserver, corVisitObserver.c.id_role == User.id_role)
        .join(Visit, Visit.id_base_visit == corVisitObserver.c.id_base_visit)
    )
    results = query.all()

    output = []
    for organism in results:
        output.append(organism.as_dict())

    replace_keys = {
        "id_organisme": "id",
        "uuid_organisme": "uuid",
        "nom_organisme": "name",
        "adresse_organisme": "address",
        "cp_organisme": "postal_code",
        "ville_organisme": "city",
        "tel_organisme": "phone",
        "fax_organisme": "fax",
        "email_organisme": "email",
        "fax_organisme": "fax",
        "url_organisme": "url",
    }
    return prepare_output(output, replace_keys=replace_keys)
