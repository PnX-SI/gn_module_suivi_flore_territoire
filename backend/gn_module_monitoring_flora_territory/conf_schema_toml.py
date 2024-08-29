"""
   Spécification du schéma toml des paramètres de configurations
   Fichier spécifiant les types des paramètres et leurs valeurs par défaut
   Fichier à ne pas modifier. Paramètres surcouchables dans config/config_gn_module.tml
"""

from marshmallow import Schema, fields

export_available_format = ["geojson", "csv", "shapefile"]

sites_list_messages = {
    "emptyMessage": "Aucun site à afficher.",
    "totalMessage": "site(s) au total",
}
visits_list_messages = {
    "emptyMessage": "Aucune visite sur ce site.",
    "totalMessage": "visite(s) au total",
}
other_visits_list_messages = {
    "emptyMessage": "Aucune autre visite sur ce site.",
    "totalMessage": "visite(s) au total",
}

sites_datatable_columns = [
    {"name": "Id", "title": "Identifiant du site", "prop": "id_base_site", "width": 50},
    {"name": "Taxon", "title": "Nom du taxon", "prop": "nom_taxon", "width": 350},
    {"name": "Nombre visites", "title": "Nombre de visites", "prop": "nb_visit", "width": 110},
    {
        "name": "Dernière visite",
        "title": "Date de la dernière visite",
        "prop": "date_max",
        "width": 120,
    },
    {
        "name": "Organismes",
        "title": "Organismes des observateurs des visites",
        "prop": "organisme",
        "width": "",
    },
]

visits_datatable_columns = [
    {
        "name": "Date de début",
        "prop": "visit_date_min",
        "width": 200,
    },
    {
        "name": "Date de fin",
        "prop": "visit_date_max",
        "width": 200,
    },
    {
        "name": "Observateur(s)",
        "prop": "observers",
        "width": 350,
    },
    {
        "name": "Présence/ Absence ? ",
        "prop": "state",
        "width": "",
    },
]

zoom_center = [44.982667966765845, 6.062455200884894]


class GnModuleSchemaConf(Schema):
    sites_datatable_columns = fields.List(fields.Dict(), load_default=sites_datatable_columns)
    sites_list_messages = fields.Dict(load_default=sites_list_messages)
    visits_datatable_columns = fields.List(fields.Dict(), load_default=visits_datatable_columns)
    visits_list_messages = fields.Dict(load_default=visits_list_messages)
    other_visits_list_messages = fields.Dict(load_default=other_visits_list_messages)
    id_dataset = fields.Integer(load_default=1)
    id_type_maille = fields.Integer(load_default=33)
    id_menu_list_user = fields.Integer(load_default=1)
    id_list_taxon = fields.Integer()
    export_available_format = fields.List(fields.String(), load_default=export_available_format)
    export_srid = fields.Integer(load_default=2154)
    zoom_center = fields.List(fields.Float(), load_default=zoom_center)
    zoom_level = fields.Integer(load_default=12)
    map_gpx_color = fields.String(load_default="green")
