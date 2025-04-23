import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';

import { NavComponent } from './nav.component';
import { provideRouter } from '@angular/router';

describe('NavComponent', () => {
  let component: NavComponent;
  let fixture: ComponentFixture<NavComponent>;

  beforeEach(waitForAsync(() => {
    TestBed.configureTestingModule({
      schemas: [CUSTOM_ELEMENTS_SCHEMA],
      imports: [NavComponent],
      providers: [provideRouter([])],
    }).compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(NavComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should display the nav link items', () => {
    expect(component.navLinks.length === 3).toBeTrue();
  });

  it('should have Employer Details, Health and Dental options', () => {
    const navArr = ['Employer Details', 'Health', 'Dental'];
    component.navLinks.map((nav) => {
      const name = nav.name;
      expect(navArr).toContain(name);
    });
  });
});
