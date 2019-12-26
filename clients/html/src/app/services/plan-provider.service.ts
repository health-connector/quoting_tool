import { Injectable } from '@angular/core';
import { ProductDataLoader } from './product-data-loader.service';
import { Product, ProductData } from '../data/products';
import { ApiRequestService } from './api-request.service';
import { saveAs } from 'file-saver';

interface ProductListUser {
  onProductsLoaded(products: Array<Product>): void;
}

@Injectable({
  providedIn: 'root'
})
export class PlanProviderService {
  public dataLoader: ProductDataLoader;

  constructor(private api_request: ApiRequestService) {
    this.dataLoader = new ProductDataLoader();
  }

  private b64toBlob = (b64Data, contentType= '', sliceSize= 512) => {
    const byteCharacters = atob(b64Data);
    const byteArrays = [];

    for (let offset = 0; offset < byteCharacters.length; offset += sliceSize) {
      const slice = byteCharacters.slice(offset, offset + sliceSize);

      const byteNumbers = new Array(slice.length);
      for (let i = 0; i < slice.length; i++) {
        byteNumbers[i] = slice.charCodeAt(i);
      }

      const byteArray = new Uint8Array(byteNumbers);
      byteArrays.push(byteArray);
    }

    const blob = new Blob(byteArrays, {type: contentType});
    return blob;
  }

  public getPlansFor(
    consumer: ProductListUser,
    sic_code: string,
    startDate: Date,
    state: string,
    county_name: string,
    zip: string,
    kind: string,
    component
  ) {
    const transformer = this.dataLoader;
    const attrs = {
      sic_code: sic_code,
      start_date: startDate,
      county_name: county_name,
      zip_code: zip,
      state: state,
      kind: kind
    };
    this.api_request.authedGet('products/plans.json', attrs).subscribe(function(data: Array<ProductData>) {
      consumer.onProductsLoaded(transformer.castData(data['plans']));
      component.isLoading = false;
    });
  }

  public getSbcDocumentFor(key, win) {
    this.api_request.authedGet('products/sbc_document.json', {key: key}).subscribe(response => {
      if (response['status'] === 'success') {
        const contentType = 'application/pdf';
        const b64Data = response['metadata'][1];
        const blob = this.b64toBlob(b64Data, contentType);
        const blobUrl = URL.createObjectURL(blob);
        win.location.href = blobUrl
      }
    });
  }
}
