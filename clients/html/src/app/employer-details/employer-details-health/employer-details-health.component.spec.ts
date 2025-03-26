import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { EmployerDetailsHealthComponent } from './employer-details-health.component';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { RouterTestingModule } from '@angular/router/testing';
import { provideHttpClientTesting } from '@angular/common/http/testing';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';

describe('EmployerDetailsHealthComponent', () => {
  let component: EmployerDetailsHealthComponent;
  let fixture: ComponentFixture<EmployerDetailsHealthComponent>;

  beforeEach(
    waitForAsync(() => {
      TestBed.configureTestingModule({
    schemas: [CUSTOM_ELEMENTS_SCHEMA],
    imports: [RouterTestingModule, EmployerDetailsHealthComponent],
    providers: [provideHttpClient(withInterceptorsFromDi()), provideHttpClientTesting()]
}).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(EmployerDetailsHealthComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should have the default paragraph text', () => {
    const text = fixture.nativeElement.querySelector('.main-text').innerText;
    expect(text).toContain('Select a benefit model to view the plans available to you');
  });
});
