from flask import Blueprint, request
from geojson import FeatureCollection

from geonature.utils.utilssqlalchemy import json_resp
from geonature.utils.env import DB
from .models import TInfoSite, TVisiteSFT

blueprint = Blueprint('pr_suivi_flore_territoire', __name__)


@blueprint.route('/sites', methods=['GET'])
@json_resp
def get_sites_zp():
    '''
    Retourne la liste des ZP
    '''
    data = DB.session.query(TInfoSite).all()
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
    data = DB.session.query(TVisiteSFT).all()
    return [d.as_dict(True) for d in data]


@blueprint.route('/visit/<id_visit>', methods=['GET'])
@json_resp
def get_visit(id_visit):
    '''
    Retourne une visite
    '''
    data = DB.session.query(TVisiteSFT).get(id_visit)
    return data.as_dict()

@blueprint.route('/visit', methods=['POST'])
@json_resp
def post_visit():
    #TODO
    return None



