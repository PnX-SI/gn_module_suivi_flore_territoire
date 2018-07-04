import { Component, OnInit, ViewChild, AfterViewInit } from "@angular/core";
import { FormControl, FormGroup, FormBuilder } from "@angular/forms";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import { maille } from "./mailleGeojson";
import { DataService } from "./services/data.service";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router } from '@angular/router';
import { GeojsonComponent } from '@geonature_common/map/geojson.component';

import { ActivatedRoute} from '@angular/router';
import { StoreService } from "./services/store.service";
import { DataFormService} from "@geonature_common/form/data-form.service"; 
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { CommonService } from '@geonature_common/service/common.service';

@Component({
selector: 'selector-afficheMaille',
templateUrl: './afficheMaille.component.html',
styleUrls: ['./afficheMaille.component.scss'],

})

export class AfficheMailleComponent implements OnInit, AfterViewInit {
public zps;
public currentZp = {};
public idSite; 
public compteAbsent = 0; 
public comptePresent = 0; 
public rest; 
public especeSuivi; 
public infoSite; 
public dateNonSet; 
public visitGrid : FormGroup; 
public visit_boo = false;
public idMaille; 
public visits = {};

@ViewChild('geojson') geojson: GeoJsonComponent
public myStylePresent = {
  color: "#008000",
  fill: true,
  fillOpacity: 0.2,
  weight: 3
};

public myStyleAbsent = {
  color: "#8B0000",
  fill: true,
  fillOpacity: 0.2,
  weight: 3
};


public codeTaxon; 

public nomTaxon;
public testTaxon; 

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

    ) {}

    ngOnInit() {
        this.idSite = this.activatedRoute.snapshot.params['id'];
        this.visitGrid = this._fb.group({
          id_base_site: this.idSite,
          id_base_visit: null,
          visit_date: null,
          cor_visit_observer: new Array(),
          cor_visit_perturbation: new Array(),
          cor_visit_grid: new Array()
        }) 

      

    }

    ngAfterViewInit(){
        this.mapService.map.doubleClickZoom.disable();

        this.activatedRoute.params.subscribe(params => {
   
            this._api.getMaille(params.id).subscribe(data => {
            this.zps = data;
              
            console.log(data.features);
            
            
            this.storeService.myGeojson = this.geojson; 
                this.geojson.currentGeoJson$.subscribe(currentLayer => {
                  
                  
                this.mapService.map.fitBounds(currentLayer.getBounds());

                });
            
            this.storeService.comptePresent = this.comptePresent ;
            this.storeService.compteAbsent =  this.compteAbsent ;
            this.storeService.totalMaille = this.zps.features.length;
            this.rest = this.zps.features.length ;
                

            })
            
              this._api.getInfoSite(params.id).subscribe(info => {
                this.infoSite = info;
                this.nomTaxon = this.dataFormService.getTaxonInfo(this.infoSite.cd_nom).subscribe(taxon => {

                  this.codeTaxon = taxon.cd_nom;              
                  this.nomTaxon = taxon.nom_valide; 
                  
                }) ;

               
             })
        })

    }
    
   
  
  
    getMailleNoVisit() {
        this.rest = this.zps.features.length - this.compteAbsent - this.comptePresent;
    }

    onEachFeature(feature, layer) {
        this.currentZp = feature.id;
        this.idMaille = feature.id;
        feature.state = 0; 
        

        layer.on({
            click: (event1 => {
             
              layer.setStyle(this.myStylePresent);
    
              if (feature.state == 2) {
                this.compteAbsent -= 1;
                this.comptePresent += 1; 
              } 
              else if (feature.state == 1) {
                this.comptePresent += 0;
              } 
              else {
                this.comptePresent += 1; 
              }
              this.getMailleNoVisit();
              feature.state = 1;
              layer.bindPopup('espèce présente dans maille!');
              this.visits[feature.id] = true; 
  
              console.log("here", this.visits);
              
              
              
        
            }),
              
    
            contextmenu: (event2 => {
              
                layer.setStyle(this.myStyleAbsent);
                if (feature.state == 1) {
                  this.comptePresent -= 1;
                  this.compteAbsent += 1;
                } else if (feature.state == 2 ) {
                  this.compteAbsent += 0;
                } else {
                  this.compteAbsent += 1;
                }
                this.getMailleNoVisit();
                layer.bindPopup('espèce absente dans maille');
                feature.state = 2;
                this.visits[feature.id] = false; 
                   
            }),
            
            dblclick: (event3 => {
              
                 layer.setStyle(this.mapService.originStyle);
                 if (feature.state == 1) {
                   this.comptePresent -= 1;
                 } else if (feature.state == 2) {
                  this.compteAbsent -= 1;
                 }
                 this.getMailleNoVisit();
                 feature.state = 0;
                 layer.bindPopup("maille pas visitée");

            })
    
            
    
          });
    

    }

    onSubmitForm() {
       
      
      const formVisit = Object.assign(
        {},
        this.visitGrid.value
      )

      formVisit['visit_date'] = this.dateParser.format(this.visitGrid.controls.visit_date.value);
      let tableauVisit = [];

      for (const key in this.visits) {
        tableauVisit.push( {
          id_area: key,
          presence: this.visits[key]
        }
      )
        
      }
      formVisit['cor_visit_grid']= tableauVisit;
      formVisit['cor_visit_observer'] = formVisit['cor_visit_observer'].map(
        obs => {
       
          return obs.id_role; 
        }
      
      )
      
      formVisit['cor_visit_perturbation'] =   formVisit['cor_visit_perturbation'].map(pertu => pertu.id_nomenclature);
     
       
      this._api.postVisit(formVisit).subscribe(
        data => {
          this.toastr.success('Visite enregistrée', '', { positionClass: 'toast-top-center' });
          setTimeout( () => this.router.navigate(['suivi_flore_territoire']), 2000);
        },
        error => {
          if (error.status === 403) {
            this._commonService.translateToaster('error', 'NotAllowed');
          
          }else {
            this._commonService.translateToaster('error', 'ErrorMessage');
        }
      }
      )
 
   }   
}
