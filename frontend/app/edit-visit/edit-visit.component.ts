import { Component, OnInit, AfterViewInit, ViewChild, } from '@angular/core';
import { FormControl, FormGroup, FormBuilder } from "@angular/forms";
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
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { CommonService } from '@geonature_common/service/common.service';


@Component({
    selector: 'selector-edit-visit',
    templateUrl: 'edit-visit.component.html',
    styleUrls: ['./edit-visit.component.scss'],

})

export class EditVisitComponent implements OnInit, AfterViewInit {
   
   public zps;
   public compteAbsent = 0; 
   public comptePresent = 0; 
   public modifGrid: FormGroup; 
   public nomTaxon;
   public date;
   public idVisit;
   public idSite;
   public namePertur = []; 
   public codePertur = [];
   public visitGrid = []; // tableau de l'objet maille visité : [{id_area: qqc, presence: true/false}]
   public observer;
   public visitModif = {}; // l'objet maille visité (modifié)
        
   @ViewChild('geojson') geojson: GeoJsonComponent
        
      constructor(public mapService: MapService, 
         public _api: DataService, 
         public activatedRoute: ActivatedRoute, 
         public storeService: StoreService, 
         public router: Router, 
         public dataFormService: DataFormService,
         private _fb: FormBuilder,
         public dateParser: NgbDateParserFormatter,
         private toastr: ToastrService,
         private _commonService: CommonService,

      ) { }
        
        
        
      ngOnInit() {
         this.idVisit = this.activatedRoute.snapshot.params['idVisit'];

         this.modifGrid = this._fb.group({
            id_base_visit: this.idVisit,
            visit_date: null,
            cor_visit_observer: new Array(),
            cor_visit_perturbation: new Array(),
            cor_visit_grid: new Array()
            })
        
         }
            
        
      ngAfterViewInit(){
         this.mapService.map.doubleClickZoom.disable();

         this.activatedRoute.params.subscribe(params => {
               
            this._api.getOneVisit(params.idVisit).subscribe( element => {
               this.visitGrid = element.cor_visit_grid;
               
               // compter l'absence/présence des mailles déjà existant
               this.visitGrid.forEach( grid => {
         
                  if (grid.presence == true) {
                     this.comptePresent += 1;
                  } else {
                     this.compteAbsent += 1;
                  }
               })

               element.cor_visit_perturbation.forEach(per => {
                  
                  const typePer = per.label_fr + ', ';
                  this.namePertur.push(typePer);
                  this.codePertur.push(per.id_nomenclature);
                  
               })
                  
                 
               this.date = element.visit_date;
               this.idSite = element.id_base_site;
                      
               this._api.getMaille(this.idSite).subscribe(data => {
                  this.zps = data;
                  this.geojson.currentGeoJson$.subscribe(currentLayer => {
                     this.mapService.map.fitBounds(currentLayer.getBounds());

                  });
    
               })
                    
               this._api.getInfoSite(this.idSite).subscribe(info => {
                  this.dataFormService.getTaxonInfo(info.cd_nom).subscribe(taxon => {
                     this.nomTaxon = taxon.nom_valide;   
                  }) 
    
               });
                
            });
               
            this._api.getVisits(this.idSite).subscribe(data => {
        
               data.forEach( visit => {
                  visit.observers.forEach( obs => {
                     this.observer = obs.nom_role + " " + obs.prenom_role;                    
                  })
                    
               });
            });
    
         })
      }
        
      

         
      onEachFeature(feature, layer) {
         // colorer mailles déjà visitées
         this.visitGrid.forEach( maille => {
               
            if(maille.id_area == feature.id) {
               if (maille.presence) {
                  layer.setStyle(this.storeService.myStylePresent);
               } else {
                  layer.setStyle(this.storeService.myStyleAbsent);
               }
            }
         });

         // évenement quand modifier statut de maille 
         layer.on({
            click: (event1 => {
               layer.setStyle(this.storeService.myStylePresent);
         
                  if (feature.state == 2) {
                     this.compteAbsent -= 1;
                     this.comptePresent += 1;
                  }
                  else if (feature.state == 1) {
                     this.comptePresent += 0;
                  } else {
                   this.comptePresent += 1;
                 }
               feature.state = 1;
               this.visitModif[feature.id] = true;  
                       
            }),
         
         
            contextmenu: (event2 => {
               layer.setStyle(this.storeService.myStyleAbsent);
                  if (feature.state == 1) {
                     this.comptePresent -= 1;
                     this.compteAbsent += 1;
                  } else if (feature.state == 2) {
                     this.compteAbsent += 0;
                  } else {
                     this.compteAbsent += 1;
                  }
               feature.state = 2;
               this.visitModif[feature.id] = false;
      
            }),
         
            dblclick: (event3 => {
         
               layer.setStyle(this.mapService.originStyle);
                  if (feature.state == 1) {
                     this.comptePresent -= 1;
                  } else if (feature.state == 2) {
                     this.compteAbsent -= 1;
                  }
               feature.state = 0;
         
            })

         });
               
      }

      onDelDate() {
         document.getElementById("ancienDate").innerHTML = "";
      }

        
      onDeletePer(item) {
         this.namePertur.splice(item, 1);
         this.codePertur.splice(item, 1)
      }


      onVisual() {
        this.router.navigate(['suivi_flore_territoire/listVisit', this.idSite]);
      }


      onModif() {
         const formModif = Object.assign(
            {},
            this.modifGrid.value
         )
      
         
         formModif['visit_date'] = this.dateParser.format(formModif['visit_date']);
      
         for (let key in this.visitModif) {
            this.visitGrid.push (
               {
                  id_area: key,
                  presence: this.visitModif[key]
               }
            )
         }

      
      formModif['cor_visit_grid'] = this.visitGrid;
      formModif['cor_visit_observer'] = formModif['cor_visit_observer'].map(
         obs => {
            return obs.id_role;
         }
      )     
      
      formModif['cor_visit_perturbation'] = formModif['cor_visit_perturbation'].map(pertu => pertu.id_nomenclature);
     
      

      console.log("test modifGrid ", formModif['cor_visit_perturbation']  );
      
      this.codePertur.forEach( elem => {
         formModif['cor_visit_perturbation'].push(elem);
      }
      )

      this._api.postVisit(formModif).subscribe(
         data => {
            this.toastr.success('Visite modifiée', '', { positionClass: 'toast-top-center' }); 
         },
         error => {
            if (error.status === 403) {
              this._commonService.translateToaster('error', 'NotAllowed');
    
            } else {
              this._commonService.translateToaster('error', 'ErrorMessage');
            }
          }

      )


      }
      
}