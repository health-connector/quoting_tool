import { TestBed } from '@angular/core/testing';

import { SelectedSicService } from './selected-sic.service';

describe('SelectedSicService', () => {
  let service: SelectedSicService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(SelectedSicService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should have initial message as "default item"', (done) => {
    service.currentMessage.subscribe((msg) => {
      expect(msg).toBe('default item');
      done();
    });
  });

  it('should update message when changeMessage is called', (done) => {
    const newMessage = 'new sic code';
    service.changeMessage(newMessage);
    service.currentMessage.subscribe((msg) => {
      expect(msg).toBe(newMessage);
      done();
    });
  });
});
