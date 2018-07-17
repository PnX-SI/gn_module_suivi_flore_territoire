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
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
@Component({
    selector: 'selector-detail-visit',
    templateUrl: 'detail-visit.component.html',
    styleUrls: ['./detail-visit.component.scss'],

})


export class DetailVisitComponent implements OnInit, AfterViewInit {
   public zps;
   public compteAbsent = 0; 
   public comptePresent = 0; 
   public codeTaxon; 
   public nomTaxon;
   public date;
   public idVisit;
   public idSite; 
   public tabPertur = []; 
   public visitGrid = [];
   public observer; 

   @ViewChild('geojson') geojson: GeoJsonComponent
    
      constructor(public mapService: MapService, 
        public _api: DataService, 
        public activatedRoute: ActivatedRoute, 
        public storeService: StoreService, 
        public router: Router, 
        public dataFormService: DataFormService,
       
      ) { }
    
    
      ngOnInit() {
        this.idVisit = this.activatedRoute.snapshot.params['idVisit'];
      }
        
    
      ngAfterViewInit(){
        this.mapService.map.doubleClickZoom.disable();
        this.activatedRoute.params.subscribe(params => {
            
            this._api.getOneVisit(params.idVisit).subscribe( element => {
              console.log("coucou ", element);
              
               this.visitGrid = element.cor_visit_grid;

               this.visitGrid.forEach( grid => {
                  if (grid.presence == true) {
                     this.comptePresent += 1;
                  } else {
                     this.compteAbsent += 1;
                  }
                    
               })

               element.cor_visit_perturbation.forEach(per => {
                  const typePer = per.label_fr + ', ';
                  this.tabPertur.push(typePer);
                  console.log("je teste ici ", this.tabPertur);
                  
               })
              
               this.date = element.visit_date;
               this.idSite = element.id_base_site
               const parametre = {
                  id_base_site: this.idSite,
               }
                
               this._api.getMaille(this.idSite).subscribe(data => {
                  this.zps = data;
                  this.geojson.currentGeoJson$.subscribe(currentLayer => {
                     this.mapService.map.fitBounds(currentLayer.getBounds());
                     let objLayer =  this.mapService.map._targets;

                  });

               })
                
               this._api.getInfoSite(this.idSite).subscribe(info => { 
                  this.dataFormService.getTaxonInfo(info.cd_nom).subscribe(taxon => {
                     this.nomTaxon = taxon.nom_valide;  
                  });
               });
            
            })   

            this._api.getVisits(this.idSite).subscribe(data => {
        
              data.forEach( visit => {
                visit.observers.forEach( obs => {
                  this.observer = obs.nom_role + " " + obs.prenom_role;                    
                })
                  
              });
             
              
           
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

}