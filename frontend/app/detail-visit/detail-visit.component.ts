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
import { ModuleConfig } from '../module.config';

@Component({
    selector: 'pnx-detail-visit',
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
        public _api: DataService, 
        public activatedRoute: ActivatedRoute, 
        public storeService: StoreService, 
        public router: Router, 
        public dataFormService: DataFormService,
       
      ) { }
    
    
      ngOnInit() {
          console.log("INIT");
          
        this.idVisit = this.activatedRoute.snapshot.params['idVisit'];
        
      }
        
    
      ngAfterViewInit(){
        this.mapService.map.doubleClickZoom.disable();
       

        this.activatedRoute.params.subscribe(params => {
            this.idVisit = params.idVisit;
            
            this._api.getOneVisit(params.idVisit).subscribe( element => {
              
               this.visitGrid = element.cor_visit_grid;
               this.comptePresent = 0;
               this.compteAbsent = 0;
               this.visitGrid.forEach( grid => {
                  if (grid.presence == true) {
                     this.comptePresent += 1;
                  } else {
                     this.compteAbsent += 1;
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
              
                
               this._api.getMaille(this.idSite).subscribe(data => {
                   console.log(data)
                  this.zps = data;
                  this.geojson.currentGeoJson$.subscribe(currentLayer => {
                     this.mapService.map.fitBounds(currentLayer.getBounds());
                  });

               })
                
               this._api.getInfoSite(this.idSite).subscribe(info => { 
                  this.dataFormService.getTaxonInfo(info.cd_nom).subscribe(taxon => {
                     this.nomTaxon = taxon.nom_valide;  
                  });
               });
       
               const parametre = {
                  id_base_site: this.idSite,
               }
              
               // ne cherger que si datalisVisit est undefinned
               this._api.getVisits(parametre).subscribe(donnee => {
                  let tabTest = [];
                  donnee.forEach ( visit => {
                     let fullName; 
                     visit.observers.forEach( obs => {
                        fullName = obs.nom_role + " " + obs.prenom_role; 
                         
                     })
                     visit.observers = fullName;
                     let tabPres = [];
                     let tabAbs = [];
                     let pres = 0;
                     let abs = 0;
                     
                     visit.cor_visit_grid.forEach( maille => {
                         if (maille.presence ) {
                             pres += 1;
                             tabPres.push(pres);
                         } else {
                             abs += 1; 
                             tabAbs.push( abs);
                         }
                     
                         
                     });
         
                     visit.state = tabPres.length + "P / " + tabAbs.length + "A ";
                    
                  });

                //   tabTest = []
                  this.dataListVisit = donnee ; 
                //   tabTest = donnee.slice();
                  
                //   console.log('passe la')
                 
                //   tabTest.forEach( test => {
                    
                //     if (test.id_base_visit == this.idVisit) {
                //        console.log("index de test ", tabTest.indexOf(test) );
                       
                //        tabTest.splice(tabTest.indexOf(test) , 1 );
                                
                //     } 
                //   })
                console.log('laaaaaaaaaaaa')
                console.log(this.idVisit);
                
                  this.rows = this.dataListVisit.filter(
                      visit => {
                        console.log(visit.id_base_visit);
                        console.log(params.idVisit);
                        
                        return visit.id_base_visit.toString() !==   params.idVisit
                       
                                                     
                        
                      }
                  )
                  console.log("cette table " , this.dataListVisit);
                
                   
                     
                    //  this.rows = tabTest;
                     
                     
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

      onNavigue() {
         this.router.navigate([`${ModuleConfig.api_url}/editVisit`, this.idVisit]);
   
      }

      onEdit(id_visit) {
         this.router.navigate([`${ModuleConfig.api_url}/editVisit`,  id_visit])
   
      }

   
      onInfo(id_visit) {
         this.router.navigate([`${ModuleConfig.api_url}/infoVisit`,  id_visit])
   
      }
}