import { Injectable, Inject } from "@angular/core";
import { HttpClient, HttpParams } from "@angular/common/http";
import { AppConfig } from "@geonature_config/app.config";

@Injectable()
export class DataService {
  constructor(private _http: HttpClient) {}

  getZp(params?) {
    let myParams = new HttpParams();
    
    for (let key in params) {
      myParams = myParams.set(key, params[key])
      
    } 
    
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/sites`, {params: myParams});
  }

  getMaille(id_base_site: number) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/gn_monitoring/siteareas/${id_base_site}`);
  }

  getInfoSite(id_base_site) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/site?id_base_site=${id_base_site}`);

  }

  postVisit(data: any) {
    console.log(data);
    console.log("déjà post ! ");
    
    
    return this._http.post<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/visit`, data)  ;

  }

  getVisits(params:any) {
    let myParams = new HttpParams();
    
    for (let key in params) {
      myParams = myParams.set(key, params[key])
      
    } 
    
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/visits`, {params: myParams});
    
    
  }
  

  getOneVisit(id_visit) {
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/visit/${id_visit}`);

  }

  downloadData(params:any) {
    let myParams = new HttpParams();
    
    for (let key in params) {
      myParams = myParams.set(key, params[key])
      
    } 
    
    return this._http.get<any>(`${AppConfig.API_ENDPOINT}/suivi_flore_territoire/export_visit`, {params: myParams});
  }
  
}
