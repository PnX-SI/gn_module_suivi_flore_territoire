'''
   Spécification du schéma toml des paramètres de configurations
   Fichier spécifiant les types des paramètres et leurs valeurs par défaut
   Fichier à ne pas modifier. Paramètres surcouchables dans config/config_gn_module.tml
'''

from marshmallow import Schema, fields

export_available_format = ['geojson', 'csv', 'shapefile']

zp_message = {
    "emptyMessage": "Aucune zone à afficher ",
    "totalMessage": "zone(s) de prospection au total"
}
list_visit_message = {
    "emptyMessage": "Aucune visite sur ce site ",
    "totalMessage": "visites au total"
}
detail_list_visit_message = {
    "emptyMessage": "Aucune autre visite sur ce site ",
    "totalMessage": "visites au total"
}

default_zp_columns = [
    {"name": "Id", "title": "Identifiant du site", "prop": "id_base_site", "width": 90},
    {"name": "Taxon", "title": "Nom du taxon", "prop": "nom_taxon", "width": 350},
    {"name": "Nombre visites", "title": "Nombre de visites", "prop": "nb_visit", "width": 120},
    {"name": "Dernière visite", "title": "Date de la dernière visite", "prop": "date_max", "width": 160},
    {"name": "Organismes", "title": "Organismes des observateurs des visites", "prop": "organisme", "width": 200},
]

default_list_visit_columns = [
    {"name": "Date", "prop": "visit_date_min"},
    {"name": "Observateur(s)", "prop": "observers"},
    {"name": "Présence/ Absence ? ", "prop": "state"},
]

zoom_center = [44.982667966765845, 6.062455200884894]

class GnModuleSchemaConf(Schema):
    zp_message = fields.Dict(load_default=zp_message)
    list_visit_message = fields.Dict(load_default=list_visit_message)
    detail_list_visit_message = fields.Dict(load_default=detail_list_visit_message)
    export_available_format = fields.List(fields.String(), load_default=export_available_format)
    default_zp_columns = fields.List(fields.Dict(), load_default=default_zp_columns)
    default_list_visit_columns = fields.List(fields.Dict(), load_default=default_list_visit_columns)
    id_dataset = fields.Integer(load_default=1)
    id_type_maille = fields.Integer(load_default=33)
    id_type_commune = fields.Integer(load_default=25)
    id_menu_list_user = fields.Integer(load_default=1)
    id_list_taxon = fields.Integer(load_default=30)
    export_srid = fields.Integer(load_default=2154)
    zoom_center = fields.List(fields.Float(), load_default=zoom_center)
    zoom_level = fields.Integer(load_default=12)
    map_gpx_color = fields.String(load_default="green")
