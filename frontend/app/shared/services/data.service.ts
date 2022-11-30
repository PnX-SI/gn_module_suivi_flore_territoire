import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';

import { ConfigService } from './config.service';

@Injectable()
export class DataService {
  apiGeoNature: string;
  apiModule: string;

  constructor(private http: HttpClient, private configService: ConfigService) {
    this.apiGeoNature = this.configService.getBackendUrl();
    this.apiModule = this.configService.getBackendModuleUrl();
  }

  getMeshes(id_base_site: number, params?: any) {
    let wsParams = new HttpParams();

    for (let key in params) {
      wsParams = wsParams.set(key, params[key]);
    }
    return this.http.get<any>(`${this.apiGeoNature}/gn_monitoring/siteareas/${id_base_site}`, {
      params: wsParams,
    });
  }

  getSites(wsParams) {
    return this.http.get<any>(`${this.apiModule}/sites`, { params: wsParams });
  }

  getOneSite(id_base_site) {
    return this.http.get<any>(`${this.apiModule}/sites/${id_base_site}`);
  }

  getVisits(params: any) {
    let wsParams = new HttpParams();

    for (let key in params) {
      wsParams = wsParams.set(key, params[key]);
    }

    return this.http.get<any>(`${this.apiModule}/visits`, { params: wsParams });
  }

  getOneVisit(id_visit) {
    return this.http.get<any>(`${this.apiModule}/visits/${id_visit}`);
  }

  addVisit(data: any) {
    return this.http.post<any>(`${this.apiModule}/visits`, data);
  }

  updateVisit(visitId: string, data: any) {
    return this.http.patch<any>(`${this.apiModule}/visits/${visitId}`, data);
  }

  getVisitsYears() {
    return this.http.get<any>(`${this.apiModule}/visits/years`);
  }

  getOrganisms() {
    return this.http.get<any>(`${this.apiModule}/organisms`);
  }

  getMunicipalities() {
    return this.http.get<any>(`${this.apiModule}/municipalities`);
  }
}
