import datetime
import time

from flask import Blueprint, request, session, current_app, send_from_directory
from sqlalchemy.sql.expression import func
from geojson import FeatureCollection, Feature
from geoalchemy2.shape import to_shape

from geonature.utils.utilssqlalchemy import json_resp, to_json_resp, to_csv_resp
from geonature.utils.env import DB, ROOT_DIR
from geonature.utils.utilsgeometry import FionaShapeService

from .models import TInfoSite, TVisiteSFT, corVisitPerturbation, CorVisitGrid, Taxonomie, ExportVisits
from .repositories import check_user_cruved_visit, check_year_visit
from geonature.core.gn_monitoring.models import corVisitObserver, TBaseVisits, TBaseSites, corSiteApplication, corSiteArea
from geonature.core.ref_geo.models import LAreas

from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from pypnusershub.db.tools import (
    InsufficientRightsError,
    get_or_fetch_user_cruved,
)
from pypnusershub import routes as fnauth

from geonature.core.users.models import TRoles, BibOrganismes

blueprint = Blueprint('pr_suivi_flore_territoire', __name__)


@blueprint.route('/sites', methods=['GET'])
@json_resp
def get_sites_zp():
    '''
    Retourne la liste des ZP
    '''
    parameters = request.args
    id_type_commune = blueprint.config['id_type_commune']
    # grâce au fichier config
    print("my id ", id_type_commune)
    q = (
        DB.session.query(
            TInfoSite,
            func.max(TBaseVisits.visit_date),
            Taxonomie.nom_complet,
            func.count(TBaseVisits.id_base_visit),
            BibOrganismes.nom_organisme,
            LAreas.area_name
        ).outerjoin(
            TBaseVisits, TBaseVisits.id_base_site == TInfoSite.id_base_site
        ).join(
            Taxonomie, TInfoSite.cd_nom == Taxonomie.cd_nom).outerjoin(
            corVisitObserver, corVisitObserver.c.id_base_visit == TVisiteSFT.id_base_visit
        ).outerjoin(
            TRoles, TRoles.id_role == corVisitObserver.c.id_role
        ).outerjoin(
            BibOrganismes, BibOrganismes.id_organisme == TRoles.id_organisme).distinct().outerjoin(
                corSiteArea, corSiteArea.c.id_base_site == TInfoSite.id_base_site).outerjoin(
                    LAreas, LAreas.id_area == corSiteArea.c.id_area).filter(LAreas.id_type == id_type_commune).group_by(
                        TInfoSite, Taxonomie.nom_complet, BibOrganismes.nom_organisme, LAreas.area_name
        ))

    if 'id_base_site' in parameters:
        q = q.filter(TInfoSite.id_base_site == parameters['id_base_site'])
    if 'id_application' in parameters:
        q = q.join(
            corSiteApplication, corSiteApplication.c.id_base_site == TInfoSite.id_base_site
        ).filter(corSiteApplication.c.id_application == parameters['id_application'])
    if 'cd_nom' in parameters:
        q = q.filter(TInfoSite.cd_nom == parameters['cd_nom'])
    if 'organisme' in parameters:
        q = q.filter(BibOrganismes.nom_organisme == parameters['organisme'])
    if 'commune' in parameters:
        q = q.filter(LAreas.area_name == parameters['commune'])
    if 'year' in parameters:
        # relance la requête pour récupérer la date_max exacte si on filtre sur l'année
        q_year = (
            DB.session.query(
                TInfoSite.id_base_site,
                func.max(TBaseVisits.visit_date),
            ).outerjoin(
                TBaseVisits, TBaseVisits.id_base_site == TInfoSite.id_base_site
            )
            .group_by(TInfoSite.id_base_site)
        )

        data_year = q_year.all()

        q = q.filter(func.date_part('year', TBaseVisits.visit_date) == parameters['year'])

    data = q.all()

    features = []
    for d in data:
        feature = d[0].get_geofeature()
        id_site = feature['properties']['base_site']['id_base_site']
        if 'year' in parameters:
            for dy in data_year:
                #  récupérer la bonne date max du site si on filtre sur année
                if id_site == dy[0]:
                    feature['properties']['date_max'] = str(dy[1])
        else:
            feature['properties']['date_max'] = str(d[1])
            if d[1] == None:
                feature['properties']['date_max'] = 'Aucune visite'
        feature['properties']['nom_taxon'] = str(d[2])
        feature['properties']['nb_visit'] = str(d[3])
        feature['properties']['organisme'] = str(d[4])
        feature['properties']['nom_commune'] = str(d[5])
        if d[4] == None:
            feature['properties']['organisme'] = 'Aucun'
        features.append(feature)
    return FeatureCollection(features)

    # return FeatureCollection([d.get_geofeature() for d in data])


@blueprint.route('/site', methods=['GET'])
@json_resp
def get_one_zp():
    '''
    Retourne une ZP à partir de l'id_base_site
    param:
        id_base_site: integer
    '''
    parameters = request.args
    q = DB.session.query(TInfoSite)
    if 'id_base_site' in parameters:
        q = q.filter(TInfoSite.id_base_site == parameters['id_base_site'])
    data = q.first()

    if data:
        return data.as_dict()
    return None


@blueprint.route('/site/<id_infos_site>', methods=['GET'])
@json_resp
def get_one_zp_id(id_infos_site):
    '''
    Retourne une ZP à partir de l'id_info_site
    '''
    data = DB.session.query(TInfoSite).get(id_infos_site)
    return data.as_dict()


@blueprint.route('/visits', methods=['GET'])
@json_resp
def get_visits():
    '''
    Retourne toutes les visites du module
    '''
    parameters = request.args
    q = DB.session.query(TVisiteSFT)
    if 'id_base_site' in parameters:
        q = q.filter(TVisiteSFT.id_base_site == parameters['id_base_site'])
    data = q.all()
    # return data.as_dict()
    return [d.as_dict(True) for d in data]

    # mydata = []
    # for d in dat:
    #     mydata.append(d.as_dict(True))
    # return mydata


@blueprint.route('/test', methods=['GET'])
@json_resp
def test():
    data = DB.session.query(TNomenclatures).all()
    return [d.as_dict(True) for d in data]


@blueprint.route('/visit/<id_visit>', methods=['GET'])
@json_resp
def get_visit(id_visit):
    '''
    Retourne une visite
    '''
    data = DB.session.query(TVisiteSFT).get(id_visit)
    return data.as_dict(recursif=True)


@blueprint.route('/visit', methods=['POST'])
@fnauth.check_auth_cruved('C', True)
@json_resp
def post_visit(info_role):
    '''
    Poste une nouvelle visite ou éditer une ancienne
    '''

    data = dict(request.get_json())

    tab_perturbation = data.pop('cor_visit_perturbation')
    tab_visit_grid = data.pop('cor_visit_grid')
    tab_observer = data.pop('cor_visit_observer')
    visit = TVisiteSFT(**data)
    # print(data)
    visit.as_dict(True)
    # pour que visit prenne en compte des relations
    # sinon elle prend pas en compte le fait qu'on efface toutes les perturbations quand on édite par ex.
    if (tab_perturbation != None):
        perturs = DB.session.query(TNomenclatures).filter(
            TNomenclatures.id_nomenclature.in_(tab_perturbation)).all()
        for per in perturs:
            visit.cor_visit_perturbation.append(per)
    for v in tab_visit_grid:
        visit_grid = CorVisitGrid(**v)
        visit.cor_visit_grid.append(visit_grid)
    observers = DB.session.query(TRoles).filter(
        TRoles.id_role.in_(tab_observer)
    ).all()
    for o in observers:
        visit.observers.append(o)
    if visit.id_base_visit:
        user_cruved = get_or_fetch_user_cruved(
            session=session,
            id_role=info_role.id_role,
            id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
        )
        update_cruved = user_cruved['U']
        check_user_cruved_visit(info_role, visit, update_cruved)
        DB.session.merge(visit)
    else:
        check_year_visit(data['id_base_site'], data['visit_date'][0:4])
        DB.session.add(visit)
    DB.session.commit()
    # print(visit.as_dict(recursif=True))

    return visit.as_dict(recursif=True)


@blueprint.route('/export_visit', methods=['GET'])
def export_visit():
    '''
    Télécharger les données d'une visite (ou des visites )
    '''

    parameters = request.args
    # q = q.filter(TInfoSite.id_base_site == parameters['id_base_site'])

    export_format = parameters['export_format'] if 'export_format' in request.args else 'shapefile'

    file_name = datetime.datetime.now().strftime('%Y_%m_%d_%Hh%Mm%S')
    q = (DB.session.query(ExportVisits))

    if 'id_base_visit' in parameters:
        q = (DB.session.query(ExportVisits)
             .filter(ExportVisits.id_base_visit == parameters['id_base_visit'])
             )
    elif 'id_base_site' in parameters:
        q = (DB.session.query(ExportVisits)
             .filter(ExportVisits.id_base_site == parameters['id_base_site'])
             )
    elif 'organisme' in parameters:
        q = (DB.session.query(ExportVisits)
             .filter(ExportVisits.organisme == parameters['organisme'])
             )
    elif 'commune' in parameters:
        q = (DB.session.query(ExportVisits)
             .filter(ExportVisits.area_name == parameters['commune'])
             )
    elif 'year' in parameters:
        q = (DB.session.query(ExportVisits)
             .filter(func.date_part('year', ExportVisits.visit_date) == parameters['year'])
             )
    elif 'cd_nom' in parameters:
        q = (DB.session.query(ExportVisits)
             .filter(ExportVisits.cd_nom == parameters['cd_nom'])
             )

    data = q.all()
    features = []

    if export_format == 'geojson':

        for d in data:
            feature = d.as_geofeature('geom', 'id_area', False)
            features.append(feature)
        result = FeatureCollection(features)

        return to_json_resp(
            result,
            as_file=True,
            filename=file_name,
            indent=4
        )

    elif export_format == 'csv':
        tab_visit = []

        for d in data:
            visit = d.as_dict()
            geom_wkt = to_shape(d.geom)
            visit['geom'] = geom_wkt

            tab_visit.append(visit)

        return to_csv_resp(
            file_name,
            tab_visit,
            tab_visit[0].keys(),
            ';'

        )

    else:
        print('LAAA')

        dir_path = str(ROOT_DIR / 'backend/static/shapefiles')

        ExportVisits.as_shape(
            geom_col='geom',
            dir_path=dir_path,
            srid=blueprint.config['export_srid'],
            data=data,
            file_name=file_name
        )

        return send_from_directory(
            dir_path,
            file_name+'.zip',
            as_attachment=True
        )


@blueprint.route('/commune/<id_application>', methods=['GET'])
@json_resp
def get_commune(id_application):
    '''
    Retourne toutes les communes présents dans le module
    '''
    params = request.args

    q = DB.session.query(LAreas.area_name).distinct().outerjoin(
        corSiteArea, LAreas.id_area == corSiteArea.c.id_area).outerjoin(
        corSiteApplication, corSiteApplication.c.id_base_site == corSiteArea.c.id_base_site).filter(
        corSiteApplication.c.id_application == id_application)

    if 'id_area_type' in params:
        q = q.filter(LAreas.id_type == params['id_area_type'])

    data = q.all()
    tab_commune = []

    for d in data:
        nom_com = dict()
        nom_com['nom_commune'] = str(d[0])
        tab_commune.append(nom_com)
    return tab_commune


@blueprint.route('/organisme', methods=['GET'])
@json_resp
def get_organisme():
    '''
    Retourne la liste de tous les organismes présents
    '''

    q = DB.session.query(
        BibOrganismes.nom_organisme, TRoles.nom_role, TRoles.prenom_role).outerjoin(
        TRoles, BibOrganismes.id_organisme == TRoles.id_organisme).distinct().join(
        corVisitObserver, TRoles.id_role == corVisitObserver.c.id_role).outerjoin(
        TVisiteSFT, corVisitObserver.c.id_base_visit == TVisiteSFT.id_base_visit)

    data = q.all()
    tab_orga = []
    for d in data:
        print("et mon d ", d)
        info_orga = dict()
        info_orga['nom_organisme'] = str(d[0])
        info_orga['observer'] = str(d[1]) + ' ' + str(d[2])
        tab_orga.append(info_orga)
    return tab_orga
