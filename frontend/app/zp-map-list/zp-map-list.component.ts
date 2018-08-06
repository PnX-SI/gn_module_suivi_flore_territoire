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
  


  
   public columns = [
       { name: 'Identifiant', prop:'id_base_site' },
       { name: 'Taxon', prop: 'nom_taxon'}, 
       { name: 'Nombre de visites', prop: 'base_site.t_base_visits.length'},
       { name: 'Date de la dernière visite', prop: 'date_max'}
              // { name: 'Actions' }
     ];
   
   public nbVisits;
   public tabNbVisits = []; 
   public dateIci; 
   public tabDate = [];
   public message = { emptyMessage: "Aucune zone à afficher ", totalMessage: "zone(s) de prospection au total" }  
   public sort = [
    {
      prop: 'identifiant',
      dir: 'desc'
    },
    // {
    //   prop: 'age',
    //   dir: 'asc'
    // }
  ]  


   constructor(public mapService: MapService, public _api: DataService, public router: Router, public storeService: StoreService,
   public mapListService:MapListService, public dataFormService: DataFormService,

   ) {}

  
   ngOnInit() {
      this.mapListService.idName = 'id_infos_site';
      let nomTaxon;  
      
      this._api.getZp().subscribe(data => {
         
         this.zps = data; 
         console.log("mes data ", data);
         
         this.mapListService.loadTableData(data);
       
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

   updateFilter (event) {
      console.log("mon event ", event)
   //  let valSearch = event.target.value.toLowerCase();

    // console.log("et quel key ici ", event.target.value);
    
   //      console.log('change')
    let result = this.mapListService.tableData.filter(
      ligne => {
         console.log('valeur ', event);
         console.log('correspond à l\'index', ligne.nom_taxon.toLowerCase().indexOf(event));
         
         
         return (ligne.nom_taxon.toLowerCase().indexOf(event) !== -1) || 
         (ligne.date_max.toLowerCase().indexOf(event) !== -1)  ;
    }
    )
    this.mapListService.tableData = result;

    // console.log("resultat ici ", this.mapListService.tableData);
    // this.mapListService.tableData.forEach( ligne => {
    //     console.log("chaque ligne" , ligne );
        
    // })
  
  }

   onSort(event) {
      
      // let tab = [2, 9 ,8 , 6, 7]
      // tab.sort((a, b) => {
      //    console.log('je veux a ', a);
      //    console.log("je veux b ", b );
         
         
      //    return a-b;
      // })
      
      console.log("sort event ", event);
      // console.log("rows ", rows);
      // console.log("tous event ", event.sorts);
      
      const sort = event.sorts[0];
      console.log("mon prop de sort ", sort.prop);
      
      // console.log("je veux ce constant  ", sort );
      
      // console.log("tableau trié ", sort.prop);
      // rows.sort() ;
      // console.log("je log rows ", rows);
      
     this.mapListService.tableData.sort((a, b) => {
      //   console.log("mon sort prop", sort.prop);
        
      //   console.log("je veux a", a.id_infos_site)
        console.log('je veux b ', b);
        ;
        
         // console.log(a[sort.prop].localeCompare(b[sort.prop] * (sort.dir === 'desc' ? -1 : 1)));
         // return a[sort.prop].localeCompare(b[sort.prop] * (sort.dir === 'desc' ? -1 : 1))
         // console.log([sort.prop]);
         console.log('je compare ', a.id_infos_site - b.id_infos_site  );
         
         return (a.id_infos_site - b.id_infos_site) || (a.nom_taxon.local.localeCompare(b.nom_taxon))  ;

      });

      // this.loading = false; 
   }
  
}
