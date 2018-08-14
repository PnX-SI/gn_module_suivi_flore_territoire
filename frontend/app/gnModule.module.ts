import { NgModule } from "@angular/core";
import { GN2CommonModule } from "@geonature_common/GN2Common.module";
import { CommonModule } from "@angular/common";
import { Routes, RouterModule } from "@angular/router";
import { ViewTestComponent } from "./view-test/view-test.component";
import { HttpClient } from "@angular/common/http";
import { DataService } from "./services/data.service";
import { HttpClientModule, HttpClientXsrfModule } from "@angular/common/http";
import { StoreService } from "./services/store.service";
import { DetailVisitComponent } from "./detail-visit/detail-visit.component";
import { ZpMapListComponent } from "./zp-map-list/zp-map-list.component";
import { ListVisitComponent } from "./list-visit/list-visit.component";
import { FormService } from "./services/form.service";
import { FormVisitComponent } from "./form-visit/form-visit.component";

// my module routing
const routes: Routes = 
[{ path: "", component: ZpMapListComponent},
 { path: "listVisit/:idSite", component: ListVisitComponent},
 {path: "editVisit/:idSite", component: FormVisitComponent},
 {path: "infoVisit/:idVisit", component: DetailVisitComponent },
 {path: "editVisit/:idSite/visit/:idVisit", component: FormVisitComponent,}

  
 ];

@NgModule({
  declarations: [ZpMapListComponent, ListVisitComponent, DetailVisitComponent, FormVisitComponent,],
  imports: [
    GN2CommonModule,
    HttpClientXsrfModule.withOptions({
      cookieName: 'token',
      headerName: 'token'
    }),
    RouterModule.forChild(routes),
    CommonModule
  ],
  providers: [HttpClient, DataService, StoreService, FormService],
  bootstrap: [],
  
})

export class GeonatureModule {

}
