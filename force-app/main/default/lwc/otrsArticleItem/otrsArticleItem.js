import { LightningElement,api } from 'lwc';
export default class OtrsArticleItem extends LightningElement {
    @api article = {};

    handleClick(event) {
        var data = event.target.value;
       // this.downloadFile(data.Content,data.FileName,data.ContentType);
        this.download(data.FileName,data.ContentType,data.Content);
        return;
    }
    downloadFile(content,filename,contentType){
        let a = document.createElement("a"); 
        a.href = 'data:application/octet-stream;base64,' +content;
        let ext = contentType.split(';')[0].split('/')[0];
        a.download = filename +'.'+ext;
        a.click(); //Downloaded file
        
    }


    download(fileName, ContentType, base64_file) {
        ContentType = 'application/octet-stream';
        console.log('ContentType '+ContentType);
       // ContentType = ContentType.includes('; ') ? ContentType.split(';')[0]:ContentType;
        const byteArray = new Uint8Array(atob(base64_file).split('').map(char=>char.charCodeAt(0)));
        let blob = new Blob([byteArray], { type:ContentType });
        let url = window.URL.createObjectURL(blob);
        let a = document.createElement('a');
        document.body.appendChild(a);
        a.setAttribute('style', 'display: none');
        a.href = url;
        a.download = fileName;
        a.click();
        window.URL.revokeObjectURL(url);
        a.remove();
    }


}