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
@Component({
    selector: 'selector-detail-visit',
    templateUrl: 'detail-visit.component.html',
    styleUrls: ['./detail-visit.component.scss'],

})



export class DetailVisitComponent implements OnInit {
    public zps;
    public currentZp = {};
    public compteAbsent = 0; 
    public comptePresent = 0; 
    public visitGrid : FormGroup; 
    public visit_boo = false;
    public idMaille; 
    public visits = {};
    public codeTaxon; 
    public nomTaxon;
    public date;
    public idVisit;
    public idSite;   
    
    @ViewChild('geojson') geojson: GeoJsonComponent
    
    constructor(public mapService: MapService, 
        public _api: DataService, 
        public activatedRoute: ActivatedRoute, 
        public storeService: StoreService, 
        public router: Router, 
        public dataFormService: DataFormService,
        private _fb: FormBuilder,
        private toastr: ToastrService,
        private _commonService: CommonService,) { }
    
    
    ngOnInit() {
        this.idVisit = this.activatedRoute.snapshot.params['idVisit'];
    }
        
    
    ngAfterViewInit(){
        this.mapService.map.doubleClickZoom.disable();
        this.activatedRoute.params.subscribe(params => {
            this._api.getOneVisit(params.idVisit).subscribe( element => {
                this.date = element.visit_date;
                this.idSite = element.id_base_site
                
                this._api.getMaille(this.idSite).subscribe(data => {
                
                    this.zps = data;
                        this.geojson.currentGeoJson$.subscribe(currentLayer => {
                            this.mapService.map.fitBounds(currentLayer.getBounds()); 
                        });
                })   
                
                this._api.getInfoSite(this.idSite).subscribe(info => {
                    this.dataFormService.getTaxonInfo(info.cd_nom).subscribe(taxon => {
                        this.codeTaxon = taxon.cd_nom;              
                        this.nomTaxon = taxon.nom_valide;   
                    }) 

            
                });
            
            })   

        })
    
    }
    
    
    onEachFeature(feature, layer) {
        this.currentZp = feature.id;
        this.idMaille = feature.id;
        feature.state = 0; 
            
        
    }

    }