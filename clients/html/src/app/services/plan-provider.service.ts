import { Injectable, inject } from '@angular/core';
import { ProductDataLoader } from './product-data-loader.service';
import { Product, ProductData } from '../data/products';
import { ApiRequestService } from './api-request.service';

interface ProductListUser {
  onProductsLoaded(products: Array<Product>): void;
}

interface PlansResponse {
  plans: ProductData[];
}

interface SbcDocumentResponse {
  status: string;
  metadata: string[];
}

@Injectable({
  providedIn: 'root',
})
export class PlanProviderService {
  private api_request = inject(ApiRequestService);
  public dataLoader: ProductDataLoader;

  constructor() {
    this.dataLoader = new ProductDataLoader();
  }

  private b64toBlob = (b64Data: string, contentType = '', sliceSize = 512): Blob => {
    const byteCharacters = atob(b64Data);
    const byteArrays: Uint8Array[] = [];

    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
      const slice = byteCharacters.slice(offset, offset + sliceSize);

      const byteNumbers = new Array(slice.length);
      for (let i = 0; i < slice.length; i++) {
        byteNumbers[i] = slice.charCodeAt(i);
      }

      const byteArray = new Uint8Array(byteNumbers);
      byteArrays.push(byteArray);
    }

    const blob = new Blob(byteArrays, { type: contentType });
    return blob;
  };

  public getPlansFor(
    consumer: ProductListUser,
    sic_code: string,
    startDate: Date,
    state: string,
    county_name: string,
    zip: string,
    kind: string,
    component: { isLoading: boolean },
  ) {
    const transformer = this.dataLoader;

    // Format the date as ISO string or any format your API expects
    const formattedStartDate = startDate.toISOString();

    const attrs = {
      sic_code: sic_code,
      start_date: formattedStartDate,
      county_name: county_name,
      zip_code: zip,
      state: state,
      kind: kind,
    };

    this.api_request.authedGet<PlansResponse>('products/plans.json', attrs).subscribe(function (data) {
      consumer.onProductsLoaded(transformer.castData(data.plans.filter((plan) => plan['rates'])));
      component.isLoading = false;
    });
  }

  public getSbcDocumentFor(key: string, win: Window) {
    this.api_request
      .authedGet<SbcDocumentResponse>('products/sbc_document.json', { key: key })
      .subscribe((response) => {
        if (response.status === 'success') {
          const contentType = 'application/pdf';
          const b64Data = response.metadata[1];
          const blob = this.b64toBlob(b64Data, contentType);
          const blobUrl = URL.createObjectURL(blob);
          win.location.href = blobUrl;
        }
      });
  }
}
