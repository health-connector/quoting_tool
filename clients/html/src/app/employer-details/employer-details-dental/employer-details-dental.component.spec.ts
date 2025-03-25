import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { EmployerDetailsDentalComponent } from './employer-details-dental.component';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { RouterTestingModule } from '@angular/router/testing';

describe('EmployerDetailsDentalComponent', () => {
  let component: EmployerDetailsDentalComponent;
  let fixture: ComponentFixture<EmployerDetailsDentalComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      declarations: [EmployerDetailsDentalComponent],
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
      imports: [RouterTestingModule]
    }).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(EmployerDetailsDentalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have the default paragraph text', () => {
    const text = fixture.nativeElement.querySelector('.main-text').innerText;
    expect(text).toContain('Choose any dental plan from a single dental insurance carrier to offer for all employees');
  });
});
