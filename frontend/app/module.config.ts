export const ModuleConfig = {
 "api_url": "/suivi_flore_territoire",
 "default_list_visit_columns": [
  {
   "name": "Date",
   "prop": "visit_date"
  },
  {
   "name": "Observateur(s)",
   "prop": "observers"
  },
  {
   "name": "Pr\u00e9sence/ Absence ? ",
   "prop": "state"
  }
 ],
 "default_zp_columns": [
  {
   "name": "Identifiant",
   "prop": "id_base_site",
   "width": 90
  },
  {
   "name": "Taxon",
   "prop": "nom_taxon",
   "width": 350
  },
  {
   "name": "Nombre de visites",
   "prop": "nb_visit",
   "width": 120
  },
  {
   "name": "Date de la derni\u00e8re visite",
   "prop": "date_max",
   "width": 160
  },
  {
   "name": "Organisme",
   "prop": "nom_organisme",
   "width": 200
  }
 ],
 "export_available_format": [
  "geojson",
  "csv",
  "shapefile"
 ],
 "id_application": 18,
 "id_menu_list_user": 10,
 "id_type_commune": 101,
 "id_type_maille": 203,
 "list_visit_message": {
  "emptyMessage": "Aucune visite sur ce site ",
  "totalMessage": "visites au total"
 },
 "zp_message": {
  "emptyMessage": "Aucune zone \u00e0 afficher ",
  "totalMessage": "zone(s) de prospection au total"
 }
}