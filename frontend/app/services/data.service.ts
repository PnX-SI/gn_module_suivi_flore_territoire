import { Injectable, Inject } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";

@Injectable()
export class DataService {
  constructor(private _http: HttpClient) {}

  getZp() {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/sites`);
  }

  getMaille(id_base_site) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_monitoring/siteareas/${id_base_site}`);
  }

  getInfoSite(id_base_site) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/site?id_base_site=${id_base_site}`);

  }

  postVisit(data) {
    console.log('et ici');
    console.log(data);
    
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/visit`, data)  ;
  }
  
}
