import { ComponentFixture, TestBed, waitForAsync } from '@angular/core/testing';

import { DropdownTreeviewSelectComponent } from './dropdown-treeview-select.component';
import { SelectedSicService } from '../services/selected-sic.service';
import { FormsModule } from '@angular/forms';
import { CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { TreeviewI18n, TreeviewI18nDefault, TreeviewModule } from 'ngx-treeview';

// At the top of your file
class MockTreeviewI18n extends TreeviewI18nDefault {
  // Override any methods that your component calls
}

describe('DropdownTreeviewSelectComponent', () => {
  let component: DropdownTreeviewSelectComponent;
  let fixture: ComponentFixture<DropdownTreeviewSelectComponent>;

  beforeEach(
    waitForAsync(() => {
      TestBed.configureTestingModule({
        imports: [FormsModule, DropdownTreeviewSelectComponent, TreeviewModule.forRoot()],
        providers: [
          { provide: TreeviewI18n, useClass: MockTreeviewI18n },
          { provide: SelectedSicService, useClass: SelectedSicService }
        ],
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
