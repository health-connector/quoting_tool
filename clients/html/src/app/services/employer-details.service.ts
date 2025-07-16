import { Injectable, inject } from '@angular/core';
import { ApiRequestService } from './api-request.service';

@Injectable({
  providedIn: 'root'
})
export class EmployerDetailsService {
  private api_request = inject(ApiRequestService);

  postUpload(upload) {
    return this.api_request.authedPost('employees/upload.json', upload);
  }

  getStartOnDates() {
    return this.api_request.authedGet('employees/start_on_dates.json');
  }
}
