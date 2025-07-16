import { TestBed } from '@angular/core/testing';

import { ApiRequestService } from './api-request.service';
import { HttpClient, HttpHandler } from '@angular/common/http';

describe('ApiRequestService', () => {
  beforeEach(() =>
    TestBed.configureTestingModule({
      providers: [ApiRequestService, HttpClient, HttpHandler]
    })
  );

  it('should be created', () => {
    const service: ApiRequestService = TestBed.inject(ApiRequestService);
    expect(service).toBeTruthy();
  });
});
