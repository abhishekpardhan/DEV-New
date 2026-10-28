import { LightningElement,api } from 'lwc';

const actions = [
    { label: 'Show details', name: 'show_details' }
];

const articleColumns = [
    { label: 'From', fieldName: 'From' },
    // { label: 'To', fieldName: 'To'},
    { label: 'Subject', fieldName: 'Subject'},
    { label: 'Update Time', fieldName: 'updateTime' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];

export default class OtrsArticles extends LightningElement {
    @api articles;
    @api recordId; 
    @api otrsTicketNumber;
    headerText;
    modalHeaderText;
    article;
    isSelectedArticleShow = false;
    articleColumns = articleColumns;
    isTableShow = false;
    isNewArticleShow ;
    newArticleHeader;


    connectedCallback(){
        this.headerText = this.articlesLabel = 'Related Articles (' + this.articles.length + ')';
        this.isTableShow = this.articles.length > 0 ? true : false;
    }
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'show_details':
                this.article = row;
                this.isSelectedArticleShow =  true;
                this.modalHeaderText = 'Showing Details for Article # '+row.ArticleId;
                break;
            default:
        }
    }
    closeModal(){
        this.isSelectedArticleShow = false;
        this.isNewArticleShow = false;
    }
    newArticle(){
        this.isNewArticleShow = true;
        this.newArticleHeader = 'New Article for Ticket # '+this.otrsTicketNumber;
    }
    addArticle(event){
        try{
        const articleObj = event.detail;
        let list = this.articles;
        console.log(JSON.stringify(articleObj));
        const newArray = [articleObj].concat(list) // [ 4, 3, 2, 1 ]
        this.articles  = newArray;
        this.headerText = this.articlesLabel = 'Related Articles (' + this.articles.length + ')';
        this.closeModal();
        }catch(e){
            console.log(e.message);
        }
    }
}