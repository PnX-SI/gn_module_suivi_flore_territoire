export const ModuleConfig = {
 "ID_MODULE": 5,
 "MODULE_CODE": "SFT",
 "MODULE_URL": "sft",
 "default_list_visit_columns": [
  {
   "name": "Date",
   "prop": "visit_date_min"
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
   "prop": "organisme",
   "width": 200
  }
 ],
 "detail_list_visit_message": {
  "emptyMessage": "Aucune autre visite sur ce site ",
  "totalMessage": "visites au total"
 },
 "export_available_format": [
  "geojson",
  "csv",
  "shapefile"
 ],
 "export_srid": 2154,
 "id_list_taxon": 30,
 "id_menu_list_user": 1,
 "id_type_commune": 25,
 "id_type_maille": 32,
 "list_visit_message": {
  "emptyMessage": "Aucune visite sur ce site ",
  "totalMessage": "visites au total"
 },
 "zoom_center": [
  44.982667966765845,
  6.062455200884894
 ],
 "zp_message": {
  "emptyMessage": "Aucune zone \u00e0 afficher ",
  "totalMessage": "zone(s) de prospection au total"
 }
}