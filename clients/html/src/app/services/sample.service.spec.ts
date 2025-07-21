import { TestBed } from '@angular/core/testing';

import { SampleService } from './sample.service';
import { ApiRequestService } from './api-request.service';
import { HttpClient, HttpHandler } from '@angular/common/http';

describe('SampleService', () => {
  beforeEach(() =>
    TestBed.configureTestingModule({
      providers: [ApiRequestService, HttpClient, HttpHandler]
    })
  );

  it('should be created', () => {
    const service: SampleService = TestBed.inject(SampleService);
    expect(service).toBeTruthy();
  });
});
