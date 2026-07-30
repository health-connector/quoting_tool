import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class SelectedSicService {
  private messageSource = new BehaviorSubject('default item');
  currentMessage = this.messageSource.asObservable();

  changeMessage(message: unknown) {
    this.messageSource.next(message as string);
  }
}
