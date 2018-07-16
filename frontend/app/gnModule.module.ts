import { NgModule } from "@angular/core";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { CommonModule } from "@angular/common";
import { Routes, RouterModule } from "@angular/router";
import { ViewTestComponent } from "./view-test/view-test.component";
import { TestComponent } from "./test.component";
import { HttpClient } from "@angular/common/http";
import { DataService } from "./services/data.service";
import { HttpClientModule } from "@angular/common/http";
import { StoreService } from "./services/store.service";
import { OcctaxFormService } from '../../../GeoNature/contrib/occtax/frontend/app/occtax-map-form/form/occtax-form.service';
import { DetailVisitComponent } from "./detail-visit/detail-visit.component";
import { RajoutVisitComponent } from "./rajout-visit/rajout-visit.component";
import { ZpMapListComponent } from "./zp-map-list/zp-map-list.component";
import { ListVisitComponent } from "./list-visit/list-visit.component";
import { EditVisitComponent } from "./edit-visit/edit-visit.component";

// my module routing
const routes: Routes = 
[{ path: "", component: ZpMapListComponent},
 { path: "afficheVisit/:idSite", component: ListVisitComponent},
 {path: "afficheMaille/:idSite", component: RajoutVisitComponent},
 {path: "infoVisit/:idVisit", component: DetailVisitComponent },
 {path: "editVisit/:idVisit", component: EditVisitComponent}
//  {path: "afficheMaille/:idSite/:idVisit", component: DetailVisitComponent}

  
 ];

@NgModule({
  declarations: [ZpMapListComponent, RajoutVisitComponent, ListVisitComponent, DetailVisitComponent, EditVisitComponent ],
  imports: [
    GN2CommonModule,
    RouterModule.forChild(routes),
    HttpClientModule,
    CommonModule
  ],
  providers: [HttpClient, DataService, StoreService, OcctaxFormService],
  bootstrap: []
})

export class GeonatureModule {

}
