import { TestBed } from '@angular/core/testing';

import { EmployerDetailsService } from './employer-details.service';
import { ApiRequestService } from './api-request.service';
import { HttpClient, HttpHandler } from '@angular/common/http';

describe('EmployerDetailsService', () => {
  beforeEach(() =>
    TestBed.configureTestingModule({
      providers: [ApiRequestService, HttpClient, HttpHandler]
    })
  );

  it('should be created', () => {
    const service: EmployerDetailsService = TestBed.inject(EmployerDetailsService);
    expect(service).toBeTruthy();
  });
});
