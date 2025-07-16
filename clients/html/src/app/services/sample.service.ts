import { Injectable, inject } from '@angular/core';
import { ApiRequestService } from './api-request.service';

@Injectable({
  providedIn: 'root'
})
export class SampleService {
  private api_request = inject(ApiRequestService);
  // Gets the message from the Rails backend
  getMessage() {
    return this.api_request.authedGet('samples');
  }
}
