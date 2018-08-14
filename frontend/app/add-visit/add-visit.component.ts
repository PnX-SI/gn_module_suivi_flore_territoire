import { Component, OnInit, ViewChild, AfterViewInit } from "@angular/core";
import { FormControl, FormGroup, FormBuilder } from "@angular/forms";
import { AppConfig } from "@geonature_config/app.config";
import { MapService } from "@geonature_common/map/map.service";
import { DataService } from "../services/data.service";
import { HttpClient, HttpParams } from "@angular/common/http";
import { Router } from '@angular/router';
import { GeojsonComponent } from '@geonature_common/map/geojson.component';

import { ActivatedRoute } from '@angular/router';
import { StoreService } from "../services/store.service";
import { DataFormService } from "@geonature_common/form/data-form.service";
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { ToastrService, ToastrConfig } from 'ngx-toastr';
import { CommonService } from '@geonature_common/service/common.service';
import { FormService } from "../services/form.service";
import { ModuleConfig} from '../module.config';

@Component({
  selector: 'selector-add-visit',
  templateUrl: './add-visit.component.html',
  styleUrls: ['./add-visit.component.scss'],

})

export class AddVisitComponent implements OnInit, AfterViewInit {
  public zps;
  public currentZp = {};
  public idSite;
  public compteAbsent = 0;
  public comptePresent = 0;
  public rest;
  public newVisitGrid: FormGroup;
  public idMaille;
  public visits = {};


  @ViewChild('geojson') geojson: GeoJsonComponent
 



  constructor(public mapService: MapService,
    public _api: DataService,
    public activatedRoute: ActivatedRoute,
    public storeService: StoreService,
    public router: Router,
    private _fb: FormBuilder,
    public dateParser: NgbDateParserFormatter,
    private toastr: ToastrService,
    private _commonService: CommonService,
    public formService: FormService
  ) { 
    
  }

  ngOnInit() {
    this.idSite = this.activatedRoute.snapshot.params['idSite'];

    this.newVisitGrid = this.formService.visitGridForm;

  }

  ngAfterViewInit() {
 
    this.mapService.map.doubleClickZoom.disable();

    this.activatedRoute.params.subscribe(params => {

      this._api.getMaille(params.idSite).subscribe(data => {
        this.zps = data;

        console.log(data.features);


        this.geojson.currentGeoJson$.subscribe(currentLayer => {


        this.mapService.map.fitBounds(currentLayer.getBounds());

        });

        this.rest = this.zps.features.length;


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

        layer.setStyle(this.storeService.myStylePresent);

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

        layer.setStyle(this.storeService.myStyleAbsent);
        if (feature.state == 1) {
          this.comptePresent -= 1;
          this.compteAbsent += 1;
        } else if (feature.state == 2) {
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

   
  onSave() {


      const formVisit = Object.assign(
         {},
         this.newVisitGrid.value
      )

      formVisit['id_base_site'] = this.idSite;

      formVisit['visit_date'] = this.dateParser.format(this.newVisitGrid.controls.visit_date.value);
      let tableauVisit = [];

      for (const key in this.visits) {
         tableauVisit.push({
            id_area: key,
            presence: this.visits[key]
         })
      }
    
      formVisit['cor_visit_grid'] = tableauVisit;

    
      formVisit['cor_visit_observer'] = formVisit['cor_visit_observer'].map(
         obs => {
            return obs.id_role;
         }
      )
    
      if ( formVisit['cor_visit_perturbation'] !== null) {
         formVisit['cor_visit_perturbation'] = formVisit['cor_visit_perturbation'].map(pertu => pertu.id_nomenclature);
      
      } else {
         console.log( " rien du tout, je suis là");
         formVisit['cor_visit_perturbation'] = [];
      }

    
      this._api.postVisit(formVisit).subscribe(
         data => {
            this.toastr.success('Visite enregistrée', '', { positionClass: 'toast-top-center' });
            setTimeout(() => this.router.navigate([`${ModuleConfig.api_url}/listVisit`, this.idSite]), 2000);
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

   onVisual() {
      this.router.navigate([`${ModuleConfig.api_url}/listVisit`, this.idSite]);

   }


 
}