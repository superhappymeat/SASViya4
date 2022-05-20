![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Collections used in this workshop

* [Instructions](#instructions)
* [Collection Index](#collection-index)
* [Collections details](#collections-details)
  * [Booking options](#booking-options)
  * [RACE machines in collection](#race-machines-in-collection)

## Instructions

* The Collection Index is a data-driving table relied on by GELLOW scripts for automation and configuration.
* list all RACE collection id's which will use GELLOW
* do not change the name or location of this file
* do not remove projects from the list
* do not change the format of the table, or the order of the columns
* the order of the lines does not matter

## Collection Index

| Type | Collection Numerical ID | Collection Name | gellow branch | Workshop Branch | Visible to Partners | Loop Category |
|  ---  |  ---  |  ---  | --- | --- | --- | --- |
| Collection | 329302 | VIYA4COLL5VMW | main | main | yes | viya4 |
| Collection | 308491 | VIYA4COLL5AZU | main | main | yes | viya4 |
| Collection | 333991 | VIYA4COLL1VMW | main | main | yes | viya4 |

## Collections details

### Booking options

* VMWare:
  * Default VMWare 5-node Collection:
    * <http://race.exnet.sas.com/Reservations?action=new&imageId=329302&imageKind=C&comment=%20GELLOW%20DEV%20VMWare&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y&admin=yes>
  * Default VMWare 1-node Collection:
    * <http://race.exnet.sas.com/Reservations?action=new&imageId=333991&imageKind=C&comment=%20GELLOW%20DEV%20VMWare&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y&admin=yes>
* Azure:
  * Default Azure 5-node collection:
    * <http://race.exnet.sas.com/Reservations?action=new&imageId=308491&imageKind=C&comment=%20GELLOW%20DEV%20Azure&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y&admin=yes>
  * Default Azure 5-node collection self-deploy:
    * <http://race.exnet.sas.com/Reservations?action=new&imageId=308491&imageKind=C&comment=%20GELLOW%20DEV%20Azure%20_GELLOWBR_feature/gelenv_&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0&discardonterminate=y&admin=yes>

### RACE machines in collection

| Machine OS | RACE image id | alias | ServerType | Name |
|  ---  |  ---  |  ---  | --- | --- |
| Linux | 1824497 | sasnode01-05 | GEL_VVOL | VIYA4_LIN_SERVER_VMW |
| Windows | 1566991 | sasclient | GEL_VVOL | VIYA4_WIN_CLIENT_VMW |
| Linux | 1824495 | sasnode01 | AzureUSEast | VIYA4_LIN_SERVER_AZU |
| Windows | 1746334 | sasclient | AzureUSEast | VIYA4_WIN_CLIENT_AZU |
