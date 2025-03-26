import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { DropdownTreeviewSelectComponent } from './dropdown-treeview-select.component';
import { SelectedSicService } from '../services/selected-sic.service';
import { FormsModule } from '@angular/forms';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { TreeviewWrapperComponent } from '../shared/treeview-wrapper/treeview-wrapper.component';

describe('DropdownTreeviewSelectComponent', () => {
  let component: DropdownTreeviewSelectComponent;
  let fixture: ComponentFixture<DropdownTreeviewSelectComponent>;

  beforeEach(
    waitForAsync(() => {
      TestBed.configureTestingModule({
        imports: [FormsModule, DropdownTreeviewSelectComponent, TreeviewWrapperComponent],
        providers: [SelectedSicService],
        schemas: [CUSTOM_ELEMENTS_SCHEMA]
      }).compileComponents();
    })
  );

  beforeEach(() => {
    fixture = TestBed.createComponent(DropdownTreeviewSelectComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
