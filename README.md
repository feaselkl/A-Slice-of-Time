# A Slice of Time
## Window Functions in SQL Server

This repository provides the supporting code for my presentation entitled [A Slice of Time:  Window Functions in SQL Server](https://www.catallaxyservices.com/presentations/a-slice-of-time/).

## Running the Code

All scripts are in the `Scripts` folder and can be run from SQL Server Management Studio, Azure Data Studio, or whatever your SQL Server query runner of choice.

In order to run this code, you will need the [WideWorldImporters database](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0).  Ideally, you will run it on SQL Server 2019, as that allows you to take advantage of batch processing over rowstore data.  If you do this, please make sure to set the compatibility level for the `WideWorldImporters` database to 150; otherwise, you will not see batch mode operations by default and would need to use a hint.

Note that some of the queries use tables named things like `OrdersSmall` or `InvoiceLinesSmall`.  I expanded the dataset in my tables but made copies of the original `Orders`, `Invoices`, and `InvoiceLines` beforehand so that I could have a smaller dataset to work with.  If you change any of these references to the original table names, you'll get the same results I do.  Or you can create these tables from the originals.
