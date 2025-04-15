import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TreeviewModule } from 'ngx-treeview';
import { NgbCollapseModule, NgbTooltipModule } from '@ng-bootstrap/ng-bootstrap';

import { NavComponent } from '../nav/nav.component';
import { DropdownTreeviewSelectComponent } from '../dropdown-treeview-select/dropdown-treeview-select.component';
import { CoverageTypePipe } from '../employer-details/coverage-type.pipe';
import { PlanFilterComponent } from '../plan-filter/plan-filter.component';
import { PlanFilterPipe } from '../plan-filter/plan-filter.pipe';
import { OrderByPipe } from '../plan-filter/order-by.pipe';

@NgModule({
  declarations: [
    NavComponent,
    DropdownTreeviewSelectComponent,
    CoverageTypePipe,
    PlanFilterComponent,
    PlanFilterPipe,
    OrderByPipe
  ],
  imports: [CommonModule, RouterModule, FormsModule, TreeviewModule.forRoot(), NgbCollapseModule, NgbTooltipModule],
  exports: [NavComponent, DropdownTreeviewSelectComponent, CoverageTypePipe, PlanFilterComponent]
})
export class SharedModule {}
