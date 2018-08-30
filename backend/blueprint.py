import datetime

from flask import Blueprint, request, session, current_app, send_from_directory
from sqlalchemy.sql.expression import func
from geojson import FeatureCollection, Feature
from geoalchemy2.shape import to_shape

from geonature.utils.utilssqlalchemy import json_resp, to_json_resp, to_csv_resp
from geonature.utils.env import DB, ROOT_DIR
from .models import TInfoSite, TVisiteSFT, corVisitPerturbation, CorVisitGrid, Taxonomie, ExportVisits
from .repositories import check_user_cruved_visit
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
#    , TBaseVisits.id_base_visit

    # t = DB.session.query(func.count(TBaseVisits.id_base_visit))
    q = (
        DB.session.query(
            TInfoSite,
            func.max(TBaseVisits.visit_date),
            Taxonomie.nom_complet,
            func.count(TBaseVisits.id_base_visit)
        ).join(
            TBaseVisits, TBaseVisits.id_base_site == TInfoSite.id_base_site
        ).join(
            Taxonomie, TInfoSite.cd_nom == Taxonomie.cd_nom)
        .group_by(TInfoSite, Taxonomie.nom_complet)
    )

    if 'id_base_site' in parameters:
        q = q.filter(TInfoSite.id_base_site == parameters['id_base_site'])
    if 'id_application' in parameters:
        q = q.join(
            corSiteApplication, corSiteApplication.c.id_base_site == TInfoSite.id_base_site
        ).filter(corSiteApplication.c.id_application == parameters['id_application'])
        # q = q.filter(TInfoSite.base_site.applications.any(id_application=parameters['id_application']))

    # print(q)
    # print(current_app.config)
    data = q.all()
    print("mes data ", data)

    features = []
    for d in data:
        print("mon d", d)
        feature = d[0].get_geofeature()
        feature['properties']['date_max'] = str(d[1])
        feature['properties']['nom_taxon'] = str(d[2])
        feature['properties']['nb_visit'] = str(d[3])
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
    print("mes roles ", info_role)
    data = dict(request.get_json())
    tab_perturbation = data.pop('cor_visit_perturbation')
    tab_visit_grid = data.pop('cor_visit_grid')
    tab_observer = data.pop('cor_visit_observer')
    visit = TVisiteSFT(**data)
    # print(data)
    print(visit.as_dict(True))
    perturs = DB.session.query(TNomenclatures).filter(
        TNomenclatures.id_nomenclature.in_(tab_perturbation)).all()
    for per in perturs:
        visit.cor_visit_perturbation.append(per)
    for v in tab_visit_grid:
        visit_grid = CorVisitGrid(**v)
        visit.cor_visit_grid.append(visit_grid)
        # print(visit_grid)
    observers = DB.session.query(TRoles).filter(
        TRoles.id_role.in_(tab_observer)
    ).all()
    # print(observers)
    for o in observers:
        # print(o.as_dict())
        visit.observers.append(o)
    if visit.id_base_visit:
        user_cruved = get_or_fetch_user_cruved(
            session=session,
            id_role=info_role.id_role,
            id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
        )
        print('coucou ', user_cruved)
        update_cruved = user_cruved['U']
        check_user_cruved_visit(info_role, visit, update_cruved)
        DB.session.merge(visit)
    else:
        DB.session.add(visit)
    DB.session.commit()
    # print(visit.as_dict(recursif=True))

    return visit.as_dict(recursif=True)


@blueprint.route('/export_visit', methods=['GET'])
def export_visit():

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

        # #TODO: mettre en parametre le srid

        dir_path = str(ROOT_DIR / 'backend/static/shapefiles')

        ExportVisits.as_shape(
            geom_col='geom',
            dir_path=dir_path,
            srid=2154,
            data=data,
            file_name=file_name
        )

        return send_from_directory(
            dir_path,
            file_name+'.zip',
            as_attachment=True
        )


@blueprint.route('/organisme', methods=['GET'])
@json_resp
def get_organisme():
    '''
    Retourne la liste des organismes
    '''
    parameters = request.args

    q = DB.session.query(
        TVisiteSFT.id_base_site,
        TRoles.nom_role,
        TRoles.prenom_role,
        BibOrganismes.nom_organisme
    ).join(
        corVisitObserver, corVisitObserver.c.id_base_visit == TVisiteSFT.id_base_visit
    ).join(
        TRoles, TRoles.id_role == corVisitObserver.c.id_role
    ).join(
        BibOrganismes, BibOrganismes.id_organisme == TRoles.id_organisme
    ).distinct()

    if 'id_base_site' in parameters:
        q = q.filter(TVisiteSFT.id_base_site == parameters['id_base_site'])

    data = q.all()
    print(data)
    # return [d.as_dict(True) for d in data]
    organism = []
    for d in data:
        info_orga = dict()
        info_orga['id_base_site'] = str(d[0])
        info_orga['observer'] = str(d[1]) + ' ' + str(d[2])
        info_orga['nom_organisme'] = str(d[3])
        organism.append(info_orga)
    # return FeatureCollection(features)
    return organism


@blueprint.route('/info_zp/<id_base_site>', methods=['GET'])
@json_resp
def get_info_zp(id_base_site):
    '''
    Retourne la/les communes d'une ZP. 
    TODO: Intégrer cette partie dans routes.py de gn_monitoring 
    '''

    params = request.args

    q = DB.session.query(
        corSiteArea,
        LAreas.area_name,
    ).join(
        LAreas,
        LAreas.id_area == corSiteArea.c.id_area
    ).filter(
        corSiteArea.c.id_base_site == id_base_site
    )

    if 'id_area_type' in params:
        q = q.filter(LAreas.id_type == params['id_area_type'])

    data = q.all()
    print("mes data ", data)
    tab_zp = []
    for d in data:
        info_zp = dict()
        info_zp['id_base_site'] = str(d[0])
        info_zp['id_area'] = str(d[1])
        info_zp['area_name'] = str(d[2])
        tab_zp.append(info_zp)
    return tab_zp
