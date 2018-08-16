import { Component, OnInit, AfterViewInit, Input, ViewChild } from "@angular/core";
import { FormControl } from "@angular/forms";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import { maille } from "./mailleGeojson";
import { DataService } from "../services/data.service";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router } from '@angular/router';
import { StoreService} from '../services/store.service';
import { MapListService } from '@geonature_common/map-list/map-list.service';
import { DataFormService} from "@geonature_common/form/data-form.service"; 
import { ModuleConfig } from '../module.config';
import { NgbDateParserFormatter} from '@ng-bootstrap/ng-bootstrap';



@Component({
  selector: "pnx-zp-map-list",
  templateUrl: "./zp-map-list.component.html",
  styleUrls: ['./zp-map-list.component.scss'],

})
export class ZpMapListComponent implements OnInit, AfterViewInit {
   public zps;
   
   public id_ZP;
  
   public rows; 

  
   public columns = [
       { name: 'Identifiant', prop:'id_base_site' },
       { name: 'Taxon', prop: 'nom_taxon'}, 
       { name: 'Nombre de visites', prop: 'nb_visit'},
       { name: 'Date de la dernière visite', prop: 'date_max'},
       { name: 'Organisme', prop: 'nom_organisme'}
              // { name: 'Actions' }
     ];
   
   public nbVisits;
   public tabNbVisits = []; 
   public dateIci; 
   public tabDate = [];
   public message = { emptyMessage: "Aucune zone à afficher ", totalMessage: "zone(s) de prospection au total" }  
   public filteredData = []; 
   public tabOrganism = [];
   public tabTestTaxon = []; 

   constructor
   (public mapService: MapService, 
    private _api: DataService, 
    public router: Router, 
    public storeService: StoreService,
    public mapListService:MapListService, 
    public dataFormService: DataFormService,

   ) {}

  
   ngOnInit() {
      this.mapListService.idName = 'id_infos_site';
      let nomTaxon;  
      
      let app = 
      {
        id_application: ModuleConfig.id_application
      
      }

      this._api.getZp(app.id_application).subscribe(data => {
         
         this.zps = data; 

         data.features.forEach(elem => {
           
            console.log("elem? ", elem);
            
            let param = {
               id_base_site: elem.properties.id_base_site
            }

            let tabOrga = [];
            this.tabOrganism = [];
            this.tabTestTaxon.push(elem.properties.nom_taxon); 

            this._api.getOrganisme(param).subscribe( organi => {
               organi.features.forEach ( res => { 

                  let org = ' ' + res.nom_organisme ;
                  tabOrga.push(org);
                  let val = tabOrga[0]; 
                  this.tabOrganism = [val]; 
                              
                  // vérifie s'il y en a différents organismes qui font des visites sur ce site 
                  //  si oui, affiche tous les organismes. Si non, affiche qu'une seule fois. 
                                  
                  tabOrga.forEach( el => {
                     if ((el !== undefined) && (el !== val)) {
                        this.tabOrganism.push(el);
                     }
                  })
                  // console.log("ma tab Filter ", tabOrganism);
                  
                  
               })
                             

               elem.properties.nom_organisme = this.tabOrganism; 
             
            })
          
           
         })

         this.mapListService.loadTableData(data);
       
         this.filteredData = this.mapListService.tableData;


      });
         
    
   }

  


   ngAfterViewInit() {
      this.mapListService.enableMapListConnexion(this.mapService.getMap()); 
     
      
   }

   onEachFeature(feature, layer) {
      this.mapListService.layerDict[feature.id] = layer;
      layer.on({
        click: (e) => {
            // toggle style
            this.mapListService.toggleStyle(layer);
            // observable
            this.mapListService.mapSelected.next(feature.id);
            // open popup
            // layer.bindPopup(feature.properties.leaflet_popup).openPopup();
        }
      });

   }


   onInfo(id_base_site) {

      this.router.navigate([`${ModuleConfig.api_url}/listVisit`,  id_base_site])

   }

   onSearchTaxon (event) {
   
      let trans = event.toLowerCase();
      this.filteredData = this.mapListService.tableData.filter(
         ligne => {
            return (ligne.nom_taxon.toLowerCase().indexOf(trans) !== -1) || !trans; 

      })
    
    
   }

  
   onSearchDate (event) {
   
   let trans = event.toLowerCase();
   this.filteredData = this.mapListService.tableData.filter(
      ligne => {
       
         return ((ligne.date_max.toLowerCase().indexOf(trans) !== -1) || !trans);
        

      })
  

   }

   onSearchOrganisme (event) {
   //  console.log("my event ", event);
   
   // let trans = event.toLowerCase();

  

   this.filteredData = this.mapListService.tableData.filter(
      ligne => {
      console.log("mes lignes ", ligne );
      
      
         for (let i = 0; i < ligne.nom_organisme.length; i++) {
            return ligne.nom_organisme[i].trim() === event; 
         //  ça marche que si l'événement === 1er élément du tableau. 
         //  cmt résoudre???
 }
       
      })

     
         }
         
  


   onSort(event) {
      // const sort = event.sorts[0];
      console.log("my event ", event );

      let prop = event.column.prop; 

      

  
      this.filteredData = this.mapListService.tableData.sort((a, b) => {
        
          return a[prop].toString().localeCompare(b[prop].toString(),  undefined,  {numeric: true}) * (event.newValue === 'desc' ? -1 : 1)  ;

      
    })

     
   }

   onDownload(format) {

    // const param = {
    //   export_format: format

    // }
    // this._api.downloadData(param).subscribe(); 
    const url = `${
      AppConfig.API_ENDPOINT}${ModuleConfig.api_url}/export_visit?export_format=${format}`;

      document.location.href = url;
    
      
}
   
  
}
