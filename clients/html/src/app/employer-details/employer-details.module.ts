import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule } from '@angular/forms';
import { AutocompleteLibModule } from 'angular-ng-autocomplete';
import { NgxDatatableModule } from '@swimlane/ngx-datatable';
import { NgbDateAdapter, NgbDateNativeAdapter, NgbModule } from '@ng-bootstrap/ng-bootstrap';

import { EmployerDetailsComponent } from './employer-details.component';
import { SharedModule } from '../shared/shared.module';
import { RouterModule } from '@angular/router';

@NgModule({
    imports: [
        CommonModule,
        RouterModule.forChild([{ path: '', component: EmployerDetailsComponent }]),
        ReactiveFormsModule,
        AutocompleteLibModule,
        NgxDatatableModule,
        NgbModule,
        SharedModule,
        EmployerDetailsComponent
    ],
    exports: [EmployerDetailsComponent],
    providers: [{ provide: NgbDateAdapter, useClass: NgbDateNativeAdapter }]
})
export class EmployerDetailsModule {}
