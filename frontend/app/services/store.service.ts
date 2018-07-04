import { Injectable } from '@angular/core';
import { Layer } from 'leaflet';

@Injectable()
export class StoreService {

public currentLayer: Layer;
public compteAbsent; 
public comptePresent ; 
public mailleNoVisit ;
public totalMaille ;
public date;  
public taxon; 
public myGeojson;
public idInfoSite; 
//public stateMaille: any [] ; 
    
    constructor() { } 
   
}