import { Component, OnInit, ViewChild, AfterViewInit } from "@angular/core";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import { maille } from "./mailleGeojson";
import { DataService } from "../services/data.service";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router } from '@angular/router';
import { GeojsonComponent } from '@geonature_common/map/geojson.component';

import { ActivatedRoute} from '@angular/router';
import { StoreService } from '../services/store.service'
import { DataFormService} from "@geonature_common/form/data-form.service"; 
import { NgbDateParserFormatter, NgbModal } from '@ng-bootstrap/ng-bootstrap';
import { ModuleConfig } from '../module.config';
import { MapListService } from '@geonature_common/map-list/map-list.service';


@Component({
    selector: 'pnx-detail-visit',
    templateUrl: 'detail-visit.component.html',
    styleUrls: ['./detail-visit.component.scss'],

})


export class DetailVisitComponent implements OnInit, AfterViewInit {
   public zps;
   public codeTaxon; 
   public nomTaxon;
   public date;
   public idVisit;
   public idSite; 
   public tabPertur = []; 
   public visitGrid = [];
   public tabObserver = []; 

   public rows = [];

   public columns = [
    { name: 'Date', prop: 'visit_date'}, 
    { name: 'Observateur(s)', prop: "observers" },
    { name: 'Présence/ Absence ? ', prop: "state"},
    { name: 'Identifiant ? ', prop: "id_base_visit"}

    // { name: 'Actions' }
  ];

  public message = { emptyMessage: "Aucune visite sur ce site ", totalMessage: "visite(s) au total" }  
  public dataListVisit = []; 


   @ViewChild('geojson') geojson: GeoJsonComponent
    
      constructor(public mapService: MapService, 
        private _api: DataService, 
        public activatedRoute: ActivatedRoute, 
        public storeService: StoreService, 
        public router: Router, 
        public dataFormService: DataFormService,
        public mapListService: MapListService, 

      ) { }
    
    
      ngOnInit() {
          console.log("INIT");
          
        this.idVisit = this.activatedRoute.snapshot.params['idVisit'];
        
      }
        
    
      ngAfterViewInit(){
        this.mapService.map.doubleClickZoom.disable();
       

        this.activatedRoute.params.subscribe(params => {
            
            this._api.getOneVisit(params.idVisit).subscribe( element => {
              
               this.visitGrid = element.cor_visit_grid;
               this.storeService.presence = 0;
               this.storeService.absence = 0; 
               this.visitGrid.forEach( grid => {
                  if (grid.presence == true) {
                     this.storeService.presence += 1;
                  } else {
                     this.storeService.absence += 1;
                  }
                    
               })

               let typePer;
               let tabVisitPerturb = element.cor_visit_perturbation;
               this.tabPertur = [];

               tabVisitPerturb.forEach(per => {
                
                  if (per == tabVisitPerturb[tabVisitPerturb.length-1] ) {
                     typePer = per.label_fr + '. ';
                  } else {
                     typePer = per.label_fr + ', ';
                  }
                  this.tabPertur.push(typePer);
                  
               })

               let fullNameObs;
               this.tabObserver = [];

               element.observers.forEach( obs => {
                  if (obs == element.observers[element.observers.length-1]) {
                     fullNameObs = obs.nom_complet + ". ";   
                  } else {
                     fullNameObs = obs.nom_complet + ", ";   
                  }
                  this.tabObserver.push(fullNameObs);
               });
               
               this.date = element.visit_date;
               this.idSite = element.id_base_site
              
               const parametre1 = {
                  id_area_type: 203
               }
                
               this._api.getMaille(this.idSite, parametre1).subscribe(data => {
               // affiche les mailles sur la carte 
                  //  console.log(data)
                  this.zps = data;
                  this.storeService.total = data.features.length;
                  console.log("cb mailles? ", this.storeService.total );
                  
                  this.storeService.getMailleNoVisit(); 
                  this.geojson.currentGeoJson$.subscribe(currentLayer => {
                     this.mapService.map.fitBounds(currentLayer.getBounds());
                  });

               })
                
               this._api.getInfoSite(this.idSite).subscribe(info => { 
                  this.dataFormService.getTaxonInfo(info.cd_nom).subscribe(taxon => {
                     this.nomTaxon = taxon.nom_valide;  
                  });
               });
       
               const parametre2 = {
                  id_base_site: this.idSite,
               }
              
               this._api.getVisits(parametre2).subscribe(donnee => {
                  donnee.forEach ( visit => {
                     let fullName; 
                     visit.observers.forEach( obs => {
                        fullName = obs.nom_role + " " + obs.prenom_role; 
                         
                     })
                     visit.observers = fullName;
                     let pres = 0;
                     let abs = 0;
                     
                     visit.cor_visit_grid.forEach( maille => {
                        if (maille.presence ) {
                           pres += 1;
                        } else {
                           abs += 1; 
                         }
                     });
         
                     visit.state = pres + "P / " + abs + "A ";
                    
                  });

                  this.dataListVisit = donnee ; 
               
                console.log('laaaaaaaaaaaa')
                
                  this.rows = this.dataListVisit.filter(
                     dataa => {
                     
                        return dataa.id_base_visit.toString() !== params.idVisit
                
                     }
                  )
                     
               })

            })   

           
         })
    
         
      }
    
    
      onEachFeature(feature, layer) {

        
        this.visitGrid.forEach( maille => {
           
            if(maille.id_area == feature.id) {
               if (maille.presence) {
                  layer.setStyle(this.storeService.myStylePresent);
               } else {
                  layer.setStyle(this.storeService.myStyleAbsent);
               }
            }
         })
      }


      onEditHere() {

         this.activatedRoute.params.subscribe(params => {
            this.router.navigate([`${ModuleConfig.api_url}/editVisit`, this.idSite, 'visit', params.idVisit]);
         })
      }


      onEditOther(id_visit) {
         this.router.navigate([`${ModuleConfig.api_url}/editVisit`, this.idSite, 'visit', id_visit])
   
      }

   
      onInfo(id_visit) {
         this.router.navigate([`${ModuleConfig.api_url}/infoVisit`,  id_visit])
   
      }
      
      onDownload(format) {
        this.activatedRoute.params.subscribe(params => {

      //   const parametre = {
      //     id_base_visit: params.idVisit,
      //     export_format : format,
      //   }

     
       const url = `${
        AppConfig.API_ENDPOINT}${ModuleConfig.api_url}/export_visit?id_base_visit=${params.idVisit}&export_format=${format}`;
  
      document.location.href = url;
     
      
   
  })
} 

 

}