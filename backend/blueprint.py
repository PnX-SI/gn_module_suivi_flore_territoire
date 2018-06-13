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







