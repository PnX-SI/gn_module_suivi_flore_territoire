from flask import Blueprint, request
from geojson import FeatureCollection

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.env import DB
from .models import TInfoSite, TVisiteSFT, corVisitPerturbation, CorVisitGrid
from geonature.core.gn_monitoring.models import corVisitObserver, TBaseVisits, TBaseSites
from pypnnomenclature.models import TNomenclatures, BibNomenclaturesTypes


from geonature.core.users.models import TRoles

blueprint = Blueprint('pr_suivi_flore_territoire', __name__)


@blueprint.route('/sites', methods=['GET'])
@json_resp
def get_sites_zp():
    '''
    Retourne la liste des ZP
    '''
    parameters = request.args 
    q = DB.session.query(TInfoSite)

    # if 'cd_nom' in parameters:
    #     q = q.filter(TInfoSite.cd_nom == parameters['cd_nom'])
    if 'id_base_site' in parameters:
        q = q.filter(TInfoSite.id_base_site == parameters['id_base_site'])

    print(q)
    data = q.all()
    return FeatureCollection([d.get_geofeature() for d in data])



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
@json_resp
def post_visit():
    data = dict(request.get_json())
    tab_perturbation = data.pop('cor_visit_perturbation')
    tab_visit_grid = data.pop('cor_visit_grid')
    tab_observer = data.pop('cor_visit_observer')
    visit = TVisiteSFT(**data)
    # print(data)
    print(visit)
    perturs = DB.session.query(TNomenclatures).filter(
        TNomenclatures.id_nomenclature.in_(tab_perturbation)).all()    
    for per in perturs:
        visit.cor_visit_perturbation.append(per)
        print(per.as_dict())
    for v in tab_visit_grid:
        visit_grid = CorVisitGrid(**v)
        visit.cor_visit_grid.append(visit_grid)
        # print(visit_grid)
    observers = DB.session.query(TRoles).filter(
        TRoles.id_role.in_(tab_observer)
        ).all()
    # print(observers)
    for o in observers:
        print(o.as_dict())
        visit.observers.append(o)
    if visit.id_base_visit:
        DB.session.merge(visit)
    else:    
        DB.session.add(visit)
    DB.session.commit()
    print(visit.as_dict(recursif=True))

    return visit.as_dict(recursif=True)



