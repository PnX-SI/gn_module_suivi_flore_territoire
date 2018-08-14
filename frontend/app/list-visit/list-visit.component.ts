import { Component, OnInit, ViewChild, AfterViewInit } from "@angular/core";
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
import { ModuleConfig } from '../module.config';
import { MapListService } from '@geonature_common/map-list/map-list.service';

@Component({
    selector: 'pnx-list-visit',
    templateUrl: 'list-visit.component.html',
    styleUrls: ['./list-visit.component.scss'],

})

export class ListVisitComponent implements OnInit, AfterViewInit {
public zps;
public nomTaxon; 
public currentZp = {};
public idSite; 
public rest; 
public especeSuivi; 
public infoSite; 
public visitGrid : FormGroup; 
public visit_boo = false;
public idMaille; 
public visits = {};
public codeTaxon; 
public idVisit;
public coordonne ; 
public message = { emptyMessage: "Aucune visite sur ce site ", totalMessage: "visites au total" }  
public rows = [];

public columns = [
    { name: 'Date', prop: 'visit_date'}, 
    { name: 'Observateur(s)', prop: "observers" },
    { name: 'Présence/ Absence ? ', prop: "state"}
    // { name: 'Actions' }
  ];

 public presence = 0; 
 public absence = 0;  

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
        public mapListService:  MapListService) { }

   ngOnInit() {
      
      this.idSite = this.activatedRoute.snapshot.params['idSite'];
      
      this._api.getInfoSite(this.idSite).subscribe(info => { 
         this.dataFormService.getTaxonInfo(info.cd_nom).subscribe(taxon => {
            this.nomTaxon = taxon.nom_valide;  
         });
      });
      
      const param = {
         id_base_site: this.idSite,
      }
        
      this._api.getVisits(param).subscribe(data => {
        console.log('mes data ', data );
         data.forEach( visit => {
            
            
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
        
         
            this.rows = data;

      
      })


   }
    
   
   ngAfterViewInit(){
      this.mapService.map.doubleClickZoom.disable();
      const parametre = {
         id_base_site: this.idSite,
         id_application: ModuleConfig.id_application,

      }
      
      this.activatedRoute.params.subscribe(params => {
        
         this._api.getZp(parametre).subscribe(data => {
             
            this.zps = data;
            this.geojson.currentGeoJson$.subscribe(currentLayer => {
                console.log("my currentLayer", currentLayer.getBounds());
                
               this.mapService.map.fitBounds(currentLayer.getBounds()); 
            });
                
               
         })
      })

   }

   onEachFeature(feature, layer) {
      this.currentZp = feature.id;
       
   }

   
   onEdit(id_visit) {
      this.router.navigate([`${ModuleConfig.api_url}/editVisit`, this.idSite, 'visit', id_visit ])

   }

   onInfo(id_visit) {
      this.router.navigate([`${ModuleConfig.api_url}/infoVisit`,  id_visit])

   }

   onAdd() {
      this.router.navigate([`${ModuleConfig.api_url}/editVisit`, this.idSite]);        
   }
   
   onDownload(format) {
    
        const url = `${
          AppConfig.API_ENDPOINT}${ModuleConfig.api_url}/export_visit?id_base_site=${this.idSite}&export_format=${format}`;
    
        document.location.href = url;
          
   }
}