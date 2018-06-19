from flask import Blueprint, request
from geojson import FeatureCollection

from geonature.utils.utilssqlalchemy import json_resp, GenericQuery
from geonature.utils.env import DB
from .models import TInfoSite

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
    '''
    parameters = request.args
    q = DB.session.query(TInfoSite)
    if 'id_base_site' in parameters:
        q = q.filter(TInfoSite.id_base_site == parameters['id_base_site'])
    data = DB.session.query(TInfoSite).one()
    return data.as_dict()

@blueprint.route('/site/<id_base_site>', methods=['GET'])
@json_resp
def get_one_zp_id(id_info_site):
    '''
    Retourne une ZP à partir de l'id_infi_site
    '''
    data = DB.session.query(TInfoSite).get(id_info_site)
    return data.as_dict()








