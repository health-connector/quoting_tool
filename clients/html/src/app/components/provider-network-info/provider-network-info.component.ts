import { Component, ChangeDetectionStrategy } from '@angular/core';
import { NgbPopover } from '@ng-bootstrap/ng-bootstrap';

@Component({
  selector: 'app-provider-network-info',
  template: `
    <button
      type="button"
      class="btn btn-link p-0 ms-2 align-baseline provider-network-info"
      aria-label="2027 provider network changes"
      [ngbPopover]="networkChanges"
      placement="bottom"
      triggers="click"
      autoClose="outside"
      popoverClass="provider-network-popover"
    >
      <i class="fas fa-info-circle fa-lg" aria-hidden="true"></i>
    </button>

    <ng-template #networkChanges>
      <p>
        Beginning in 2027, Tufts Direct will no longer be offering plans in Berkshire County. Please review Tufts
        Direct's 2027 provider network carefully and contact your provider, call Tufts Direct at 888-257-1985 (TTY:
        711) or visit
        <a href="https://tuftshealthplan.com/find-a-doctor" target="_blank" rel="noopener noreferrer"
          >Find a provider | Tufts Health Plan</a
        >
        to confirm whether your preferred providers remain in-network before enrolling in 2027 coverage. Please note
        the Health Connector continues to offer a wide selection of plan options from numerous carriers, through which
        members may continue to access health care providers in the Berkshire County.
      </p>
      <p class="mb-0">
        Beginning in 2027, Fallon will no longer be offering plans in various regions throughout Massachusetts
        including Berkshire, Bristol, Norfolk, Plymouth, and Suffolk counties, as well as parts of Hampden, Middlesex,
        and Worcester counties. Please review Fallon's 2027 provider network carefully and contact your provider, call
        Fallon at 800-868-5200 (TRS 711) or visit
        <a href="https://fchp.org/findphysician/" target="_blank" rel="noopener noreferrer"
          >Massachusetts health insurance - Fallon Health</a
        >
        to confirm whether your preferred providers remain in-network before enrolling in 2027 coverage. Please note
        the Health Connector continues to offer a wide selection of plan options from numerous carriers, through which
        members may continue to access health care providers in these affected counties.
      </p>
    </ng-template>
  `,
  styles: [
    `
      :host ::ng-deep .provider-network-popover {
        max-width: 480px;
      }
    `,
  ],
  changeDetection: ChangeDetectionStrategy.Eager,
  imports: [NgbPopover],
})
export class ProviderNetworkInfoComponent {}
