import { Injectable, Inject } from "@angular/core";
import { FormControl, FormGroup, FormBuilder } from "@angular/forms";

@Injectable()
export class FormService {

   public visitGridForm : FormGroup ;
      
   


   constructor(private _fb : FormBuilder) {
      this.visitGridForm = _fb.group(
         { 
            id_base_site: null,
            id_base_visit: null,
            visit_date: null,
            cor_visit_observer: new Array(),
            cor_visit_perturbation: new Array(),
            cor_visit_grid: new Array(),
        }
      )
    
   }

   
   

}