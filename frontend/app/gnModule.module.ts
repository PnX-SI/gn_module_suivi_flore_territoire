import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { HttpClientXsrfModule } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { GN2CommonModule } from '@geonature_common/GN2Common.module';

import { ConfigService } from './shared/services/config.service';
import { DataService } from './shared/services/data.service';
import { StoreService } from './shared/services/store.service';

import { BreadcrumbsComponent } from './shared/components/breadcrumbs/breadcrumbs.component';
import { VisitDetailComponent } from './visit-details/visit-details.component';
import { VisitFormComponent } from './visit-form/visit-form.component';
import { routes } from './gnModule.routes';
import { SiteDetailsComponent } from './site-details/site-details.component';
import { SitesMapListComponent } from './sites-map-list/sites-map-list.component';

@NgModule({
  declarations: [
    BreadcrumbsComponent,
    SitesMapListComponent,
    SiteDetailsComponent,
    VisitDetailComponent,
    VisitFormComponent,
  ],
  imports: [
    GN2CommonModule,
    HttpClientXsrfModule.withOptions({
      cookieName: 'token',
      headerName: 'token',
    }),
    RouterModule.forChild(routes),
    CommonModule,
  ],
  providers: [HttpClient, ConfigService, DataService, StoreService],
  bootstrap: [],
})
export class GeonatureModule {}
