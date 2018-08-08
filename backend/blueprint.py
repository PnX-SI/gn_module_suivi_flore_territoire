from flask import Blueprint, request, session, current_app
from sqlalchemy.sql.expression import func
from geojson import FeatureCollection

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.env import DB
from .models import TInfoSite, TVisiteSFT, corVisitPerturbation, CorVisitGrid, Taxonomie
from .repositories import check_user_cruved_visit
from geonature.core.gn_monitoring.models import corVisitObserver, TBaseVisits, TBaseSites, corSiteApplication
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes
from pypnusershub.db.tools import (
    InsufficientRightsError,
    get_or_fetch_user_cruved,
)
from pypnusershub import routes as fnauth

from geonature.core.users.models import TRoles

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
    # print("je veux ici ", t.all())
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
   
    # q = DB.session.query(TInfoSite, func.max(TBaseVisits.visit_date)).join(
    #     TBaseVisits, TInfoSite.id_base_site == TBaseVisits.id_base_site).group_by(TInfoSite)
    if 'id_base_site' in parameters:
        q = q.filter(TInfoSite.id_base_site == parameters['id_base_site'])
    if 'id_application' in parameters:
        q = q.join(
            corSiteApplication, corSiteApplication.c.id_base_site == TInfoSite.id_base_site
        ).filter(corSiteApplication.c.id_application == parameters['id_application'])
        # q = q.filter(TInfoSite.base_site.applications.any(id_application=parameters['id_application']))
    

    # print(q)
    print(current_app.config)
    data = q.all()

    features = []
    for d in data:
        print (d)
        feature = d[0].get_geofeature()
        feature['properties']['date_max'] = str(d[1])
        feature['properties']['nom_taxon'] = str(d[2])
        feature['properties']['nb_visit'] = str(d[3])
        features.append(feature)
    return FeatureCollection(features)
    # return "here"

  
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
    # print(info_role)
    data = dict(request.get_json())
    tab_perturbation = data.pop('cor_visit_perturbation')
    tab_visit_grid = data.pop('cor_visit_grid')
    tab_observer = data.pop('cor_visit_observer')
    visit = TVisiteSFT(**data)
    # print(data)
    # print(visit)
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
            id_role=user.id_role,
            id_application_parent=current_app.config['ID_APPLICATION_GEONATURE']
        )
        update_cruved = user_cruved['U']
        check_user_cruved_visit(info_role, visit, update_cruved)
        DB.session.merge(visit)
    else:    
        DB.session.add(visit)
    DB.session.commit()
    # print(visit.as_dict(recursif=True))

    return visit.as_dict(recursif=True)



