import { Component, OnInit } from '@angular/core';
import { NgbDateParserFormatter } from '@ng-bootstrap/ng-bootstrap';
import { CustomDateParserFormatter } from './custom_date_parser_formatter';
import { FooterComponent } from './components/footer/footer.component';
import { RouterOutlet } from '@angular/router';
import { HeaderComponent } from './components/header/header.component';

@Component({
  providers: [{ provide: NgbDateParserFormatter, useClass: CustomDateParserFormatter }],
  selector: 'app-root',
  standalone: true,
  template: `
    <app-header />
    <router-outlet />
    <app-footer />
  `,
  imports: [HeaderComponent, RouterOutlet, FooterComponent],
})
export class AppComponent implements OnInit {
  ngOnInit() {
    localStorage.removeItem('employerDetails');
  }
}
