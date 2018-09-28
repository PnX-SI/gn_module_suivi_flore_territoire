'''
   Spécification du schéma toml des paramètres de configurations
'''

from marshmallow import Schema, fields
from geonature.utils.config_schema import GnModuleProdConf


available_export_format = ['geojson', 'csv', 'shapefile']

zp_message = {"emptyMessage": "Aucune zone à afficher ", "totalMessage": "zone(s) de prospection au total"}
list_visit_message = {"emptyMessage": "Aucune visite sur ce site ", "totalMessage": "visites au total"}
detail_list_visit_message = {"emptyMessage": "Aucune autre visite sur ce site ", "totalMessage": "visites au total"}

default_maplist_zp_columns = [
    {"name": 'Identifiant', "prop": 'id_base_site', "width": 90},
    {"name": 'Taxon', "prop": 'nom_taxon', "width": 350},
    {"name": 'Nombre de visites', "prop": 'nb_visit', "width": 120},
    {"name": 'Date de la dernière visite', "prop": 'date_max', "width": 160},
    {"name": 'Organisme', "prop": 'organisme', "width": 200}
]

default_list_visit_columns = [
    {"name": 'Date', "prop": 'visit_date_min'},
    {"name": 'Observateur(s)', "prop": "observers"},
    {"name": 'Présence/ Absence ? ', "prop": "state"},
    # {"name": 'identifiant', "prop": "id_base_visit"}

]

coor_zoom_center = [44.982667966765845, 6.062455200884894]


class GnModuleSchemaConf(GnModuleProdConf):
    zp_message = fields.Dict(missing=zp_message)
    list_visit_message = fields.Dict(missing=list_visit_message)
    detail_list_visit_message = fields.Dict(missing=detail_list_visit_message)
    export_available_format = fields.List(fields.String(), missing=available_export_format)
    default_zp_columns = fields.List(fields.Dict(), missing=default_maplist_zp_columns)
    default_list_visit_columns = fields.List(fields.Dict(), missing=default_list_visit_columns)
    id_type_maille = fields.Integer(missing=32)
    id_type_commune = fields.Integer(missing=25)
    id_menu_list_user = fields.Integer(missing=1)
    id_list_taxon = fields.Integer(missing=100)
    export_srid = fields.Integer(missing=2154)
    zoom_center = fields.List(fields.Float(), missing=coor_zoom_center)
